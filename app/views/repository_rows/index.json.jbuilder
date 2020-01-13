# frozen_string_literal: true

json.draw @draw
json.recordsTotal @all_rows_count
json.recordsFiltered @filtered_rows_count
json.data do
  json.array! prepare_row_columns(@repository_rows,
                                  @repository,
                                  @columns_mappings,
                                  @repository.team)
end
