# frozen_string_literal: true

class StorageLocationRepositoryRow < ApplicationRecord
  include Discard::Model
  include SearchableModel

  default_scope -> { kept }

  belongs_to :storage_location, inverse_of: :storage_location_repository_rows
  belongs_to :container_storage_location, -> { where(container: true) },
             class_name: 'StorageLocation',
             foreign_key: 'storage_location_id',
             inverse_of: :storage_location_repository_rows
  belongs_to :repository_row, inverse_of: :storage_location_repository_rows
  belongs_to :created_by, class_name: 'User'

  with_options if: -> { storage_location.container && storage_location.metadata['display_type'] == 'grid' } do
    validate :position_must_be_present
    validate :ensure_uniq_position
  end

  with_options if: -> { storage_location.container && storage_location.metadata['display_type'] != 'grid' } do
    validate :unique_repository_row
  end

  def human_readable_position
    return unless metadata['position']

    column_letter = ('A'..'Z').to_a[metadata['position'][0] - 1]
    row_number = metadata['position'][1]

    "#{column_letter}#{row_number}"
  end

  def position_must_be_present
    errors.add(:base, I18n.t('activerecord.errors.models.storage_location.missing_position')) if metadata['position'].blank?
  end

  def ensure_uniq_position
    if storage_location.storage_location_repository_rows
                       .where("metadata->'position' = ?", metadata['position'].to_json)
                       .where.not(id: id).exists?
      errors.add(:base, I18n.t('activerecord.errors.models.storage_location.not_uniq_position'))
    end
  end

  def unique_repository_row
    if storage_location.storage_location_repository_rows
                       .where(repository_row_id: repository_row_id)
                       .where.not(id: id).exists?
      errors.add(:base, I18n.t('activerecord.errors.models.storage_location.not_uniq_repository_row'))
    end
  end
end
