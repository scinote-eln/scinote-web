# frozen_string_literal: true

class Table < ApplicationRecord
  include SearchableModel
  include TableHelper
  include ObservableModel

  SEARCHABLE_ATTRIBUTES = ['tables.name', 'tables.data_vector'].freeze

  SIGNIFICANT_METADATA_KEYS = %w(
    sheet_name
    cells_merge
    cells_style
    plateTemplate
    cells_properties
    columns_properties
  ).freeze

  auto_strip_attributes :name, nullify: false
  validates :name,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :contents,
            presence: true,
            length: { maximum: Constants::TABLE_JSON_MAX_SIZE_MB.megabytes }

  belongs_to :created_by,
             foreign_key: 'created_by_id',
             class_name: 'User',
             optional: true
  belongs_to :last_modified_by,
             foreign_key: 'last_modified_by_id',
             class_name: 'User',
             optional: true
  belongs_to :team, optional: true
  has_one :step_table, inverse_of: :table, dependent: :destroy
  has_one :step, through: :step_table, touch: true

  has_one :result_table, inverse_of: :table, dependent: :destroy
  has_one :result, through: :result_table, touch: true, class_name: 'ResultBase'
  has_many :report_elements, inverse_of: :table, dependent: :destroy

  after_save :update_ts_index

  def metadata
    attributes['metadata'].is_a?(String) ? JSON.parse(attributes['metadata']) : attributes['metadata']
  end

  def update_metadata!(new_metadata)
    ActiveRecord::Base.transaction do
      # support for legacy tables
      self.metadata ||= {}

      # ignore column and cell width changes within columns_properties and cells_properties
      metadata.merge!(
        new_metadata.slice(*SIGNIFICANT_METADATA_KEYS - %w(columns_properties cells_properties))
      )

      self.metadata['columns_properties'] = new_metadata['columns_properties'].map do |column|
        current_column_width = metadata['columns_properties']&.find { |c| c['x'] == column['x'] }&.dig('properties', 'width')

        column.merge(
          'properties' =>
            column['properties'].merge('width' => current_column_width || column['properties']['width'])
        )
      end

      self.metadata['cells_properties'] = new_metadata['cells_properties'].map do |row|
        current_cell_width = metadata['cells_properties']&.find { |c| [c['x'], c['y']] == [row['x'], row['y']] }&.dig('properties', 'width')

        row.merge(
          'properties' =>
            row['properties'].merge('width' => current_cell_width || row['properties']['width'])
        )
      end

      save! if metadata_changed?

      # update non-significant metadata fields directly, without callbacks
      # rubocop:disable Rails/SkipsModelValidations
      new_metadata = metadata.deep_merge(new_metadata.except(*(SIGNIFICANT_METADATA_KEYS - %w(columns_properties))))
      update_column(:metadata, new_metadata) if metadata != new_metadata
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def contents_utf_8
    contents.present? ? contents.force_encoding(Encoding::UTF_8) : nil
  end

  def update_ts_index
    if saved_change_to_contents?
      sql = "UPDATE tables " +
            "SET data_vector = " +
            "to_tsvector(substring(encode(contents::bytea, 'escape'), 9)) " +
            "WHERE id = " + Integer(id).to_s
      Table.connection.execute(sql)
    end
  end

  def well_plate?
    metadata&.dig('plateTemplate') || false
  end

  def to_csv
    require 'csv'

    data = JSON.parse(contents)['data']
    CSV.generate do |csv|
     data.each do |row|
       csv << row
     end
    end
  end

  def duplicate(parent, user, position = nil)
    case parent
    when Step
      ActiveRecord::Base.transaction do
        new_table = parent.tables.create!(
          name: name,
          contents: contents.encode('UTF-8', 'UTF-8'),
          team: parent.protocol.team,
          created_by: user,
          metadata: metadata,
          last_modified_by: user
        )

        parent.step_orderable_elements.create!(
          position: position || parent.step_orderable_elements.length,
          orderable: new_table.step_table
        )

        new_table
      end
    when ResultTemplate
      ActiveRecord::Base.transaction do
        new_table = parent.tables.create!(
          name: name,
          contents: contents.encode('UTF-8', 'UTF-8'),
          team: parent.protocol.team,
          created_by: user,
          metadata: metadata,
          last_modified_by: user
        )
        parent.result_orderable_elements.create!(
          position: position || parent.result_orderable_elements.length,
          orderable: new_table.result_table
        )

        new_table
      end
    when Result
      ActiveRecord::Base.transaction do
        new_table = parent.tables.create!(
          name: name,
          contents: contents.encode('UTF-8', 'UTF-8'),
          team: parent.my_module.team,
          created_by: user,
          metadata: metadata,
          last_modified_by: user
        )

        parent.result_orderable_elements.create!(
          position: position || parent.result_orderable_elements.length,
          orderable: new_table.result_table
        )

        new_table
      end
    end
  end
end
