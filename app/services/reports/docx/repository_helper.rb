# frozen_string_literal: true

module Reports::Docx::RepositoryHelper
  include InputSanitizeHelper

  def prepare_row_columns(repository_data)
    result = [repository_data[:headers]]
    repository_data[:data].repository_rows.each do |record|
      row = []
      row.push(record.id)
      row.push(escape_input(record.name))
      row.push(I18n.l(record.created_at, format: :full))
      row.push(escape_input(record.created_by.full_name))

      custom_cells = record.repository_cells
      repository_data[:data].mappings.each do |column_id, _position|
        value = custom_cells.find_by(repository_column_id: column_id)&.value&.formatted
        row.push(value)
      end

      result.push(row)
    end

    result
  end
end
