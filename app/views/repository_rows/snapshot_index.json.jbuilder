# frozen_string_literal: true

json.draw @draw
json.data do
  json.array! prepare_snapshot_row_columns(@repository_rows,
                                           @columns_mappings,
                                           @repository_snapshot.team,
                                           @repository_snapshot,
                                           @my_module)
end
json.recordsFiltered @filtered_rows_count
json.recordsTotal @all_rows_count
