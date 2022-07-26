# frozen_string_literal: true

json.draw @draw
json.data do
  json.array! prepare_snapshot_row_columns(@repository_rows,
                                           @columns_mappings,
                                           @repository_snapshot.team,
                                           @repository_snapshot)
end
json.recordsFiltered @repository_rows.first ? @repository_rows.first.filtered_count : 0
json.recordsTotal @all_rows_count
