# frozen_string_literal: true

class RepositoryCell < ApplicationRecord
  include ReminderRepositoryCellJoinable

  attr_accessor :importing

  belongs_to :repository_row
  belongs_to :repository_column
  belongs_to :value, polymorphic: true, inverse_of: :repository_cell, dependent: :destroy

  {
    repository_text: 'RepositoryTextValue',
    repository_number: 'RepositoryNumberValue',
    repository_list: 'RepositoryListValue',
    repository_asset: 'RepositoryAssetValue',
    repository_status: 'RepositoryStatusValue',
    repository_checklist: 'RepositoryChecklistValue',
    repository_date_time: 'RepositoryDateTimeValueBase',
    repository_time: 'RepositoryDateTimeValueBase',
    repository_date: 'RepositoryDateTimeValueBase',
    repository_date_time_range: 'RepositoryDateTimeRangeValueBase',
    repository_time_range: 'RepositoryDateTimeRangeValueBase',
    repository_date_range: 'RepositoryDateTimeRangeValueBase',
    repository_stock: 'RepositoryStockValue',
    repository_stock_consumption_snapshot: 'RepositoryStockConsumptionValue'
  }.each do |relation, class_name|
    belongs_to "#{relation}_value".to_sym,
               (lambda do |repository_cell|
                 repository_cell.value_type == class_name ? self : none
               end),
               optional: true, foreign_key: :value_id, inverse_of: :repository_cell
  end

  has_many :hidden_repository_cell_reminders, dependent: :destroy

  validates :repository_column,
            inclusion: { in: (lambda do |repository_cell|
              repository_cell.repository_row&.repository&.repository_columns || []
            end) },
            unless: :importing
  validates :repository_column, presence: true
  validate :repository_column_data_type
  validates :repository_row,
            uniqueness: { scope: :repository_column },
            unless: :importing

  scope :with_active_reminder, lambda { |user|
    reminder_repository_cells_scope(self, user)
  }

  def self.create_with_value!(row, column, data, user)
    cell = new(repository_row: row, repository_column: column)
    cell.transaction do
      value_klass = column.data_type.constantize
      value = value_klass.new_with_payload(data, repository_cell: cell,
                                                 created_by: user,
                                                 last_modified_by: user)
      cell.value = value
      value.save!
    end
    cell
  end

  def snapshot!(row_snapshot)
    cell_snapshot = dup
    column_snapshot = row_snapshot.repository
                                  .repository_columns
                                  .find { |c| c.parent_id == repository_column.id }
    cell_snapshot.assign_attributes(
      repository_row: row_snapshot,
      repository_column: column_snapshot,
      created_at: created_at,
      updated_at: updated_at
    )
    value.snapshot!(cell_snapshot)
    cell_snapshot
  end

  private

  def repository_column_data_type
    if !repository_column || value.class.name != repository_column.data_type
      errors.add(:value_type, 'must match column data type')
    end
  end
end
