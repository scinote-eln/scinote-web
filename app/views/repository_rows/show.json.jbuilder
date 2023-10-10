# frozen_string_literal: true

json.id @repository_row.id
json.repository_name @repository.name
json.permissions do
  json.can_export_repository_stock can_export_repository_stock?(@repository_row.repository)
end
json.default_columns do
  json.name @repository_row.name
  json.code @repository_row.code
  json.added_on @repository_row.created_at
  json.added_by @repository_row.created_by&.full_name
  json.archived @repository_row.archived?
end
json.custom_columns do
  json.array! @repository_row.repository_cells do |repository_cell|
    json.merge!(**serialize_repository_cell_value(
      repository_cell, @repository.team, @repository, reminders_enabled: @reminders_present
    ), **repository_cell.repository_column.as_json(only: %i(id name data_type)))
  end
end

json.assigned_modules do
  json.total_assigned_size @assigned_modules.size
  json.viewable_modules do
    json.array! @viewable_modules do |my_module|
      json.merge! serialize_assigned_my_module_value(my_module)
    end
  end
end
