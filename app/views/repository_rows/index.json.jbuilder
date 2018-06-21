json.draw @draw
json.recordsTotal @repository_rows.total_count
json.recordsFiltered @repository_row_count
json.data do
  json.array! prepare_row_columns(@repository_rows,
                                  @repository,
                                  @columns_mappings,
                                  @repository.team,
                                  @assigned_rows)
end
