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
  EXTRA_SORTABLE_VALUE_INCLUDE = { asset: { file_attachment: :blob } }.freeze
  EXTRA_PRELOAD_INCLUDE = { asset: { file_attachment: :blob } }.freeze

  def formatted
    asset.file_name
  end

  def self.add_filter_condition(repository_rows, join_alias, filter_element)
    case filter_element.operator
    when 'file_contains'
      s_query = filter_element.parameters['text']&.gsub(/[!()&|:]/, ' ')&.strip&.split(/\s+/)
      return repository_rows if s_query.blank?

      asset_join_alias = "#{join_alias}_assets"
      asset_text_join_alias = "#{join_alias}_asset_text_data"

      s_query = s_query.map { |t| "#{t}:*" }.join('|').tr('\'', '"')
      repository_rows
        .joins(
          "INNER JOIN \"assets\" AS \"#{asset_join_alias}\" ON "\
          "\"#{asset_join_alias}\".\"id\" = \"#{join_alias}\".\"asset_id\""
        ).joins(
          "INNER JOIN \"asset_text_data\" AS \"#{asset_text_join_alias}\" ON "\
          "\"#{asset_text_join_alias}\".\"asset_id\" = \"#{asset_join_alias}\".\"id\""
        ).where("\"#{asset_text_join_alias}\".data_vector @@ to_tsquery(?)", s_query)
    when 'file_attached'
      repository_rows.where.not("#{join_alias} IS NULL")
    else
      raise ArgumentError, 'Wrong operator for RepositoryAssetValue!'
    end
  end

  def data
    asset.file_name
  end

  def data_different?(_new_data)
    true
  end

  def update_data!(new_data, user)
    if new_data.is_a?(String) # assume it's a signed_id_token
      asset.file.attach(new_data)
    elsif new_data[:file_data]
      asset.file.attach(io: StringIO.new(Base64.decode64(new_data[:file_data])), filename: new_data[:file_name])
    end

    asset.file_pdf_preview.purge if asset.file_pdf_preview.attached?

    asset.last_modified_by = user
    self.last_modified_by = user
    asset.save! && save!
    asset.post_process_file
  end

  def snapshot!(cell_snapshot)
    value_snapshot = dup
    asset_snapshot = asset.dup
    # Needed to handle shared repositories from another teams
    asset_snapshot.team_id = cell_snapshot.repository_column.repository.team_id

    asset_snapshot.save!

    # ActiveStorage::Blob is immutable, so we can just attach it to the new snapshot
    asset_snapshot.file.attach(asset.blob)

    value_snapshot.assign_attributes(
      repository_cell: cell_snapshot,
      asset: asset_snapshot,
      created_at: created_at,
      updated_at: updated_at
    )
    value_snapshot.save!
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    team = value.repository_cell.repository_column.repository.team
    value.asset = Asset.create!(created_by: value.created_by, last_modified_by: value.created_by, team: team)

    if payload.is_a?(String) # assume it's a signed_id_token
      value.asset.file.attach(payload)
    elsif payload[:file_data]
      value.asset.file.attach(io: StringIO.new(Base64.decode64(payload[:file_data])), filename: payload[:file_name])
    end

    value.asset.post_process_file
    value
  end

  alias export_formatted formatted
end
