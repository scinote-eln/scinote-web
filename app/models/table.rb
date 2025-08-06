# frozen_string_literal: true

class Table < ApplicationRecord
  include SearchableModel
  include TableHelper
  include ObservableModel

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
  has_one :result, through: :result_table, touch: true
  has_many :report_elements, inverse_of: :table, dependent: :destroy

  after_save :update_ts_index

  def metadata
    attributes['metadata'].is_a?(String) ? JSON.parse(attributes['metadata']) : attributes['metadata']
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

  def run_observers
    AutomationObservers::ProtocolContentChangedAutomationObserver.new(step, step&.last_modified_by).call
  end
end
