# frozen_string_literal: true

json.id @repository_row.id
json.repository_name @repository.name
json.default_columns do
  json.name @repository_row.name
  json.code @repository_row.code
  json.added_on @repository_row.created_at
  json.added_by @repository_row.created_by&.full_name
  json.archived @repository_row.archived?
end
json.custom_columns do
  json.array! @repository_row.repository_cells do |repository_cell|
    json.merge! serialize_repository_cell_value(repository_cell, @repository.team, @repository).merge(
      repository_cell.repository_column.as_json(only: %i(id name data_type))
    )
  end
end
