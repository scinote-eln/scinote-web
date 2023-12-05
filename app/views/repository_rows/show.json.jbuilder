# frozen_string_literal: true

json.id @repository_row.id
json.repository do
  json.id @repository.id
  json.name @repository.name
end

json.update_path update_cell_repository_repository_row_path(@repository, @repository_row)

json.permissions do
  json.can_export_repository_stock can_export_repository_stock?(@repository)
  json.can_manage can_manage_repository_rows?(@repository) if @repository.is_a?(Repository)
end

json.actions do
  if @my_module.present?
    json.assign_repository_row do
      json.assign_url my_module_repositories_path(@my_module.id)
      json.disabled @my_module_assign_error.present?
    end
  end
  json.direct_file_upload_path rails_direct_uploads_url
  if @repository_row.has_stock?
    json.stock_value_url edit_repository_stock_repository_repository_row_url(@repository, @repository_row)
  elsif @repository.has_stock_management?
    json.stock_value_url new_repository_stock_repository_repository_row_url(@repository, @repository_row)
  end
end

json.default_columns do
  json.name @repository_row.name
  json.code @repository_row.code
  json.added_on I18n.l(@repository_row.created_at, format: :full)
  json.added_by @repository_row.created_by&.full_name
  json.archived @repository_row.archived?
  if @repository_row.archived?
    json.archived_on I18n.l(@repository_row.archived_on, format: :full)
    json.archived_by @repository_row.archived_by
  end
end

json.custom_columns do
  json.array! repository_columns_ordered_by_state(@repository_row.repository).each do |repository_column|
    repository_cell = @repository_row.repository_cells.find_by(repository_column: repository_column)

    options = case repository_column.data_type
              when 'RepositoryListValue'
                {
                  options_path: items_repository_repository_columns_list_column_path(@repository, repository_column)
                }
              when 'RepositoryStatusValue'
                {
                  options_path: items_repository_repository_columns_status_column_path(@repository, repository_column)
                }
              when 'RepositoryChecklistValue'
                {
                  options_path: items_repository_repository_columns_checklist_column_path(@repository, repository_column)
                }
              when 'RepositoryNumberValue'
                {
                  decimals: repository_column.metadata.fetch(
                    'decimals', Constants::REPOSITORY_NUMBER_TYPE_DEFAULT_DECIMALS
                  ).to_i
                }
              else
                {
                  options_path: ''
                }
              end

    if repository_cell
      json.merge! serialize_repository_cell_value(
        repository_cell, @repository.team, @repository, reminders_enabled: @reminders_present
      ).merge(
        repository_cell.repository_column.as_json(only: %i(id name data_type))
      ).merge(options)
    else
      json.merge! repository_column.as_json(only: %i(id name data_type)).merge(options)
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
