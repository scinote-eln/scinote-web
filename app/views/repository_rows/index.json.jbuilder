# frozen_string_literal: true

json.draw @draw
json.data do
  json.array! prepare_row_columns(@repository_rows,
                                  @repository,
                                  @columns_mappings,
                                  @repository.team,
                                  (@datatable_params || {}).merge(omit_editable: true))
end
json.recordsFiltered @filtered_rows_count
json.recordsTotal @all_rows_count
