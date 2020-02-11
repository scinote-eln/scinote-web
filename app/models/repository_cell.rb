# frozen_string_literal: true

class RepositoryCell < ApplicationRecord
  attr_accessor :importing

  belongs_to :repository_row
  belongs_to :repository_column
  belongs_to :value, polymorphic: true,
                     inverse_of: :repository_cell,
                     dependent: :destroy
  belongs_to :repository_text_value,
             (lambda do
               includes(:repository_cell)
               .where(repository_cells: { value_type: 'RepositoryTextValue' })
             end),
             optional: true, foreign_key: :value_id
  belongs_to :repository_number_value,
             (lambda do
               includes(:repository_cell)
               .where(repository_cells: { value_type: 'RepositoryNumberValue' })
             end),
             optional: true, foreign_key: :value_id
  belongs_to :repository_date_value,
             (lambda do
               includes(:repository_cell)
               .where(repository_cells: { value_type: 'RepositoryDateTimeValueBase' })
             end),
             optional: true, foreign_key: :value_id
  belongs_to :repository_list_value,
             (lambda do
               includes(:repository_cell)
               .where(repository_cells: { value_type: 'RepositoryListValue' })
             end),
             optional: true, foreign_key: :value_id
  belongs_to :repository_asset_value,
             (lambda do
               includes(:repository_cell)
               .where(repository_cells: { value_type: 'RepositoryAssetValue' })
             end),
             optional: true, foreign_key: :value_id

  belongs_to :repository_status_value,
             (lambda do
               includes(:repository_cell)
                 .where(repository_cells: { value_type: 'RepositoryStatusValue' })
             end),
             optional: true, foreign_key: :value_id

  belongs_to :repository_checklist_value,
             (lambda do
               includes(:repository_cell)
                 .where(repository_cells: { value_type: 'RepositoryChecklistValue' })
             end),
             optional: true, foreign_key: :value_id

  belongs_to :repository_date_time_value_base,
             (lambda do
               includes(:repository_cell)
                 .where(repository_cells: { value_type: 'RepositoryDateTimeValueBase' })
             end),
             optional: true, foreign_key: :value_id

  belongs_to :repository_date_time_value,
             (lambda do
               includes(:repository_cell)
                 .where(repository_cells: { value_type: 'RepositoryDateTimeValueBase' })
             end),
             optional: true, foreign_key: :value_id

  belongs_to :repository_time_value,
             (lambda do
               includes(:repository_cell)
                 .where(repository_cells: { value_type: 'RepositoryDateTimeValueBase' })
             end),
             optional: true, foreign_key: :value_id

  belongs_to :repository_date_time_range_value_base,
             (lambda do
               includes(:repository_cell)
                 .where(repository_cells: { value_type: 'RepositoryDateTimeRangeValueBase' })
             end),
             optional: true, foreign_key: :value_id

  belongs_to :repository_date_time_range_value,
             (lambda do
               includes(:repository_cell)
                 .where(repository_cells: { value_type: 'RepositoryDateTimeRangeValueBase' })
             end),
             optional: true, foreign_key: :value_id

  belongs_to :repository_date_range_value,
             (lambda do
               includes(:repository_cell)
                 .where(repository_cells: { value_type: 'RepositoryDateTimeRangeValueBase' })
             end),
             optional: true, foreign_key: :value_id

  belongs_to :repository_time_range_value,
             (lambda do
               includes(:repository_cell)
                 .where(repository_cells: { value_type: 'RepositoryDateTimeRangeValueBase' })
             end),
             optional: true, foreign_key: :value_id

  validates :repository_column,
            inclusion: { in: (lambda do |cell|
              cell.repository_row&.repository&.repository_columns || []
            end) },
            unless: :importing
  validates :repository_column, presence: true
  validate :repository_column_data_type
  validates :repository_row,
            uniqueness: { scope: :repository_column },
            unless: :importing

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

  private

  def repository_column_data_type
    if !repository_column || value.class.name != repository_column.data_type
      errors.add(:value_type, 'must match column data type')
    end
  end
end
