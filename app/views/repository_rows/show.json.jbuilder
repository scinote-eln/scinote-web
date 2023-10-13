# frozen_string_literal: true

json.id @repository_row.id

json.repository do
  json.id @repository.id
  json.name @repository.name
end

json.permissions do
  json.can_export_repository_stock can_export_repository_stock?(@repository_row.repository)
end

json.actions do
  if @my_module.present?
    json.assign_repository_row do
      json.assign_url my_module_repositories_path(@my_module.id)
      json.disabled @my_module_assign_error.present?
    end
  end
end

json.default_columns do
  json.name @repository_row.name
  json.code @repository_row.code
  json.added_on I18n.l(@repository_row.created_at, format: :full)
  json.added_by @repository_row.created_by&.full_name
  json.archived @repository_row.archived?
end

json.custom_columns do
  json.array! @repository_row.repository.repository_columns.each do |repository_column|
    repository_cell = @repository_row.repository_cells.find_by(repository_column: repository_column)
    if repository_cell
      json.merge! **serialize_repository_cell_value(repository_cell, @repository.team, @repository, reminders_enabled: @reminders_present).merge(
        **repository_cell.repository_column.as_json(only: %i(id name data_type))
      )
    else
      json.merge! repository_column.as_json(only: %i(id name data_type))
    end
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
