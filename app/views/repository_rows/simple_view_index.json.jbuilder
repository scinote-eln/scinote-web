# frozen_string_literal: true

json.draw @draw
json.data do
  json.array! prepare_simple_view_row_columns(
    @repository_rows, @repository, @my_module, { include_stock_consumption: @repository.has_stock_management? }
  )
end
json.recordsFiltered @repository_rows.first ? @repository_rows.first.filtered_count : 0
json.recordsTotal @all_rows_count
