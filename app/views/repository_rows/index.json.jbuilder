# frozen_string_literal: true

json.draw @draw
json.data do
  json.array! prepare_row_columns(@repository_rows,
                                  @repository,
                                  @columns_mappings,
                                  @repository.team)
end
json.recordsFiltered @repository_rows.first ? @repository_rows.first.filtered_count : 0
json.recordsTotal @all_rows_count
