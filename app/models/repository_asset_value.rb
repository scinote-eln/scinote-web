# frozen_string_literal: true

class RepositoryAssetValue < ApplicationRecord
  belongs_to :created_by,
             foreign_key: :created_by_id,
             class_name: 'User',
             optional: true
  belongs_to :last_modified_by,
             foreign_key: :last_modified_by_id,
             class_name: 'User',
             optional: true
  belongs_to :asset,
             inverse_of: :repository_asset_value,
             dependent: :destroy
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  accepts_nested_attributes_for :repository_cell

  validates :asset, :repository_cell, presence: true

  SORTABLE_COLUMN_NAME = 'active_storage_blobs.filename'
  SORTABLE_VALUE_INCLUDE = { repository_asset_value: { asset: { file_attachment: :blob } } }.freeze

  def formatted
    asset.file_name
  end

  def data
    asset.file_name
  end

  def data_changed?(_new_data)
    true
  end

  def update_data!(new_data, user)
    destroy! && return if new_data == '-1'

    if new_data[:direct_upload_token]
      asset.file.attach(new_data[:direct_upload_token])
    else
      asset.file.attach(io: StringIO.new(Base64.decode64(new_data[:file_data].split(',')[1])),
                        filename: new_data[:filename])
    end

    asset.last_modified_by = user
    self.last_modified_by = user
    asset.save! && save!
  end

  def self.new_with_payload(payload, attributes)
    raise ArgumentError, 'Payload needs to be a hash' unless payload.is_a?(Hash)

    value = new(attributes)
    team = value.repository_cell.repository_column.repository.team
    value.asset = Asset.create!(created_by: value.created_by, last_modified_by: value.created_by, team: team)

    if payload[:direct_upload_token]
      value.asset.file.attach(payload[:direct_upload_token])
    elsif payload[:file_data]
      value.asset.file.attach(
        io: StringIO.new(Base64.decode64(payload[:file_data].split(',')[1])),
        filename: payload[:filename]
      )
    end

    value.asset.post_process_file(team)
    value
  end
end
