# frozen_string_literal: true

module Reports::Docx::RepositoryHelper
  include InputSanitizeHelper

  def prepare_row_columns(repository_data)
    result = [repository_data[:headers]]
    repository_data[:rows].each do |record|
      row = []
      row.push(record.id)
      row.push(escape_input(record.name))
      row.push(I18n.l(record.created_at, format: :full))
      row.push(escape_input(record.created_by.full_name))

      cell_values = {}
      custom_cells = record.repository_cells
      custom_cells.each do |cell|
        cell_values[cell.repository_column_id] = cell.value.formatted
      end

      repository_data[:custom_columns].each do |column_id|
        value = cell_values[column_id]
        row.push(value)
      end

      result.push(row)
    end

    result
  end
end
