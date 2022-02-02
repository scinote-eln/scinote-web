# frozen_string_literal: true

module Reports::Docx::RepositoryHelper
  include InputSanitizeHelper

  def prepare_row_columns(repository_data, my_module)
    result = [repository_data[:headers]]
    repository_data[:rows].each do |record|
      row = []
      row.push(record.code)
      row.push(escape_input(record.archived ? "#{record.name} [#{I18n.t('general.archived')}]" : record.name))
      row.push(I18n.l(record.created_at, format: :full))
      row.push(escape_input(record.created_by.full_name))

      cell_values = {}
      custom_cells = record.repository_cells
      custom_cells.each do |cell|
        if cell.value.instance_of? RepositoryStockValue
          consumption = record.my_module_repository_rows.find_by(my_module: my_module).stock_consumption || 0
          unit = cell.value.repository_stock_unit_item&.data
          cell_values[cell.repository_column_id] = "#{consumption} #{unit}"
        else
          cell_values[cell.repository_column_id] = cell.value.formatted
        end
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
