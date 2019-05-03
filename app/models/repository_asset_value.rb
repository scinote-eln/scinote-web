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

  def formatted
    asset.file_file_name
  end

  def data
    asset.file_file_name
  end

  def data_changed?(_new_data)
    true
  end

  def update_data!(new_data, user)
    file = Paperclip.io_adapters.for(new_data[:file_data])
    file.original_filename = new_data[:file_name]
    asset.file = file
    asset.last_modified_by = user
    self.last_modified_by = user
    asset.save! && save!
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    team = value.repository_cell.repository_column.repository.team
    file = Paperclip.io_adapters.for(payload[:file_data])
    file.original_filename = payload[:file_name]
    value.asset = Asset.create!(
      file: file,
      created_by: value.created_by,
      last_modified_by: value.created_by,
      team: team
    )
    value.asset.post_process_file(team)
    value
  end
end
