# frozen_string_literal: true

module Reports::Docx::RepositoryHelper
  include InputSanitizeHelper
  include ActionView::Helpers::NumberHelper

  def prepare_row_columns_for_docx(repository_data, my_module = nil, repository = nil)
    return if repository_data[:headers].blank?

    result = [repository_data[:headers]]
    excluded_columns = repository_data[:excluded_columns]

    repository_data[:rows].each do |record|
      row = []
      row.push(record.code) unless excluded_columns.include?(-1)
      unless excluded_columns.include?(-2)
        row_tags = []
        row_tags << "[#{I18n.t('general.archived')}]" if record.archived
        row_tags << "[#{I18n.t('general.output')}]" if my_module && record.output? && my_module.id == record.my_module_id
        row.push(escape_input("#{record.name} #{row_tags.join(' ')}"))
      end
      row.push(I18n.l(record.created_at, format: :full)) unless excluded_columns.include?(-3)
      row.push(escape_input(record.created_by.full_name)) unless excluded_columns.include?(-4)

      cell_values = {}
      custom_cells = record.repository_cells
      custom_cells.each do |cell|
        if cell.value.instance_of?(RepositoryStockValue) && my_module
          if repository.is_a?(RepositorySnapshot)
            consumed_stock = record.repository_stock_consumption_cell&.value&.formatted || 0
            cell_values[cell.repository_column_id] = consumed_stock
          else
            consumption = number_with_precision(
              record.my_module_repository_rows.find_by(my_module: my_module)&.stock_consumption || 0,
              precision: (record.repository.repository_stock_column.metadata['decimals'].to_i || 0),
              strip_insignificant_zeros: true
            )
            unit = cell.value.repository_stock_unit_item&.data
            cell_values[cell.repository_column_id] = "#{consumption} #{unit}"
          end
        else
          cell_values[cell.repository_column_id] = cell.value.formatted
        end
      end
      if repository.repository_stock_column.present? && record.repository_stock_cell.blank?
        cell_values[repository.repository_stock_column.id] = '-'
      end

      repository_data[:custom_columns].each do |column_id|
        next if excluded_columns.include?(column_id)

        value = cell_values[column_id]
        row.push(value)
      end

      result.push(row)
    end

    result
  end
end
