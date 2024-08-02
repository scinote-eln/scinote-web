# frozen_string_literal: true

class StorageLocation < ApplicationRecord
  include Cloneable
  include Discard::Model
  ID_PREFIX = 'SL'
  include PrefixedIdModel

  default_scope -> { kept }

  has_one_attached :image

  belongs_to :team
  belongs_to :parent, class_name: 'StorageLocation', optional: true
  belongs_to :created_by, class_name: 'User'

  has_many :storage_location_repository_rows, inverse_of: :storage_location
  has_many :storage_locations, foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent
  has_many :repository_rows, through: :storage_location_repository_row

  validates :name, length: { maximum: Constants::NAME_MAX_LENGTH }
  validate :parent_validation, if: -> { parent.present? }

  after_discard do
    StorageLocation.where(parent_id: id).find_each(&:discard)
    storage_location_repository_rows.each(&:discard)
  end

  def duplicate!
    ActiveRecord::Base.transaction do
      new_storage_location = dup
      new_storage_location.name = next_clone_name
      new_storage_location.save!
      copy_image(self, new_storage_location)
      recursive_duplicate(id, new_storage_location.id)
      new_storage_location
    rescue ActiveRecord::RecordInvalid
      false
    end
  end

  def with_grid?
    metadata['display_type'] == 'grid'
  end

  def grid_size
    metadata['dimensions'] if with_grid?
  end

  def available_positions
    return unless with_grid?

    occupied_positions = storage_location_repository_rows.pluck(:metadata).map { |metadata| metadata['position'] }

    rows = {}

    grid_size[0].times do |row|
      rows_cells = []
      grid_size[1].times.filter_map do |col|
        rows_cells.push(col + 1) if occupied_positions.exclude?([row + 1, col + 1])
      end
      rows[row + 1] = rows_cells unless rows_cells.empty?
    end

    rows
  end

  def self.storage_locations_enabled?
    ApplicationSettings.instance.values['storage_locations_enabled']
  end

  private

  def recursive_duplicate(old_parent_id = nil, new_parent_id = nil)
    StorageLocation.where(parent_id: old_parent_id).find_each do |child|
      new_child = child.dup
      new_child.parent_id = new_parent_id
      new_child.save!
      copy_image(child, new_child)
      recursive_duplicate(child.id, new_child.id)
    end
  end

  def copy_image(old_storage_location, new_storage_location)
    return unless old_storage_location.image.attached?

    old_blob = old_storage_location.image.blob
    old_blob.open do |tmp_file|
      to_blob = ActiveStorage::Blob.create_and_upload!(
        io: tmp_file,
        filename: old_blob.filename,
        metadata: old_blob.metadata
      )
      new_storage_location.image.attach(to_blob)
    end
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
