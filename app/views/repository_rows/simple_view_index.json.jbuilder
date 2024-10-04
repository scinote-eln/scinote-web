# frozen_string_literal: true

json.draw @draw
json.data do
  json.array! prepare_simple_view_row_columns(
    @repository_rows, @repository, @my_module, @datatable_params || {}
  )
end
json.recordsFiltered @filtered_rows_count
json.recordsTotal @all_rows_count
