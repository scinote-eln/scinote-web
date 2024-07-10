# frozen_string_literal: true

class StorageLocationRepositoryRow < ApplicationRecord
  include Discard::Model

  default_scope -> { kept }

  belongs_to :storage_location, inverse_of: :storage_location_repository_rows
  belongs_to :repository_row, inverse_of: :storage_location_repository_rows
  belongs_to :created_by, class_name: 'User'

  with_options if: -> { storage_location.container && storage_location.metadata['type'] == 'grid' } do
    validate :position_must_be_present
    validate :ensure_uniq_position
  end

  def position_must_be_present
    if metadata['position'].blank?
      errors.add(:base, I18n.t('activerecord.errors.models.storage_location.missing_position'))
    end
  end

  def ensure_uniq_position
    if StorageLocationRepositoryRow.where(storage_location: storage_location)
                                   .where('metadata @> ?', { position: metadata['position'] }.to_json)
                                   .where.not(id: id).exists?
      errors.add(:base, I18n.t('activerecord.errors.models.storage_location.not_uniq_position'))
    end
  end
end
