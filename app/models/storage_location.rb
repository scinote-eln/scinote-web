# frozen_string_literal: true

class StorageLocation < ApplicationRecord
  include Discard::Model
  ID_PREFIX = 'SL'
  include PrefixedIdModel

  default_scope -> { kept }

  has_one_attached :image

  belongs_to :team
  belongs_to :parent, class_name: 'StorageLocation', optional: true
  belongs_to :created_by, class_name: 'User'

  has_many :storage_location_repository_rows, inverse_of: :storage_location
  has_many :repository_rows, through: :storage_location_repository_row

  validates :name, length: { maximum: Constants::NAME_MAX_LENGTH }
  validate :parent_validation, if: -> { parent.present? }

  after_discard do
    StorageLocation.where(parent_id: id).find_each(&:discard)
    storage_location_repository_rows.each(&:discard)
  end

  def self.inner_storage_locations(team, storage_location = nil)
    entry_point_condition = storage_location ? 'parent_id = ?' : 'parent_id IS NULL'

    inner_storage_locations_sql =
      "WITH RECURSIVE inner_storage_locations(id, selected_storage_locations_ids) AS (
        SELECT id, ARRAY[id]
        FROM storage_locations
        WHERE team_id = ? AND #{entry_point_condition}
        UNION ALL
        SELECT storage_locations.id, selected_storage_locations_ids || storage_locations.id
        FROM inner_storage_locations
        JOIN storage_locations ON storage_locations.parent_id = inner_storage_locations.id
        WHERE NOT storage_locations.id = ANY(selected_storage_locations_ids)
      )
      SELECT id FROM inner_storage_locations ORDER BY selected_storage_locations_ids".gsub(/\n|\t/, ' ').squeeze(' ')

    if storage_location.present?
      where("storage_locations.id IN (#{inner_storage_locations_sql})", team.id, storage_location.id)
    else
      where("storage_locations.id IN (#{inner_storage_locations_sql})", team.id)
    end
  end

  def parent_validation
    if parent.id == id
      errors.add(:parent, I18n.t('activerecord.errors.models.storage_location.attributes.parent_storage_location'))
    elsif StorageLocation.inner_storage_locations(team, self).exists?(id: parent_id)
      errors.add(:parent, I18n.t('activerecord.errors.models.project_folder.attributes.parent_storage_location_child'))
    end
  end
end
