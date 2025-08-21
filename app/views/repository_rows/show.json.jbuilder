# frozen_string_literal: true

# handle deleted repos
@repository ||= Repository.new(id: @repository_row.repository_id)
@repository_row.repository = @repository

json.id @repository_row.id
if @repository_row.snapshot_at
  json.snapshot_at DateTime.parse(@repository_row.snapshot_at).strftime("#{I18n.backend.date_format} %H:%M")
  json.snapshot_by_name @repository_row.snapshot_by_name
end

json.repository do
  json.id @repository.id
  json.name @repository.name
  json.is_snapshot @repository.is_a?(RepositorySnapshot) || !@repository_row.snapshot_at.nil?
end
json.editable @repository_row.editable?
json.notification @notification

json.update_path update_cell_repository_repository_row_path(@repository, @repository_row)

json.permissions do
  json.can_export_repository_stock @repository_row.snapshot_at.nil? && can_export_repository_stock?(@repository)
  json.can_manage @repository_row.snapshot_at.nil? && can_manage_repository_rows?(@repository) if @repository.is_a?(Repository) && !@repository.is_a?(SoftLockedRepository)
  json.can_connect_rows @repository_row.snapshot_at.nil? && can_connect_repository_rows?(@repository) if @repository.is_a?(Repository) && !@repository.is_a?(SoftLockedRepository)
end

json.actions do
  if @my_module.present?
    json.assign_repository_row do
      json.assign_url my_module_repositories_path(@my_module.id)
      json.disabled @my_module_assign_error.present?
    end
  end
  json.direct_file_upload_path rails_direct_uploads_url
  if @repository_row.has_stock? && @repository.has_stock_management?
    json.stock_value_url edit_repository_stock_repository_repository_row_url(@repository, @repository_row)
  elsif @repository.has_stock_management?
    json.stock_value_url new_repository_stock_repository_repository_row_url(@repository, @repository_row)
  end
  json.row_connections do
    json.inventories_url repository_row_connections_repositories_url
    json.inventory_items_url repository_rows_repository_repository_row_repository_row_connections_path(@repository,
                                                                                                       @repository_row)
    json.create_url repository_repository_row_repository_row_connections_url(@repository, @repository_row)
  end
end

json.storage_locations do
  json.locations(
    @repository_row.storage_locations.distinct.map do |storage_location|
      readable = can_read_storage_location?(storage_location)

      {
        id: storage_location.id,
        readable: readable,
        name: readable ? storage_location.name : storage_location.code,
        metadata: storage_location.metadata,
        breadcrumbs: storage_location.breadcrumbs(readable: readable),
        positions: readable ? storage_location.storage_location_repository_rows.where(repository_row: @repository_row) : []
      }
    end
  )
  json.enabled StorageLocation.storage_locations_enabled?
  json.placeholder storage_locations_placeholder
end

json.default_columns do
  json.name @repository_row.name
  json.code @repository_row.code
  json.added_on I18n.l(@repository_row.created_at, format: :full)
  json.added_by @repository_row.created_by&.full_name
  json.updated_on I18n.l(@repository_row.updated_at, format: :full)
  json.updated_by @repository_row.last_modified_by&.full_name
  json.archived @repository_row.archived?
  if @repository_row.archived?
    json.archived_on I18n.l(@repository_row.archived_on, format: :full)
    json.archived_by @repository_row.archived_by
  end
end

json.relationships do
  json.parents_count @repository_row.parent_connections_count
  json.children_count @repository_row.child_connections_count
  json.parents do
    json.array! @repository_row.parent_repository_rows.preload(:repository).each do |parent|
      json.id parent.id
      json.code parent.code
      if can_read_repository?(parent.repository)
        json.name parent.name_with_label
        json.path repository_repository_row_path(parent.repository, parent)
        json.repository_name parent.repository.name_with_label
        json.repository_path repository_path(parent.repository)
      else
        json.name I18n.t('repositories.item_card.relationships.private_item_name')
      end
      json.can_connect_rows can_connect_repository_rows?(parent.repository) if parent.repository.is_a?(Repository) && !parent.repository.is_a?(SoftLockedRepository)
      json.unlink_path repository_repository_row_repository_row_connection_path(parent.repository,
                                                                                parent,
                                                                                @repository_row.parent_connections
                                                                                               .find_by(parent: parent))
    end
  end
  json.children do
    json.array! @repository_row.child_repository_rows.preload(:repository).each do |child|
      json.id child.id
      json.code child.code
      if can_read_repository?(child.repository)
        json.name child.name_with_label
        json.path repository_repository_row_path(child.repository, child)
        json.repository_name child.repository.name_with_label
        json.repository_path repository_path(child.repository)
      else
        json.name I18n.t('repositories.item_card.relationships.private_item_name')
      end
      json.can_connect_rows can_connect_repository_rows?(child.repository) if child.repository.is_a?(Repository) && !child.repository.is_a?(SoftLockedRepository)
      json.unlink_path repository_repository_row_repository_row_connection_path(child.repository,
                                                                                child,
                                                                                @repository_row.child_connections
                                                                                               .find_by(child: child))
    end
  end
end

json.custom_columns do
  json.array! repository_columns_ordered_by_state(@repository_row.repository).each do |repository_column|
    repository_cell = @repository_row.repository_cells.find { |c| c.repository_column_id == repository_column.id }

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
      json.formatted_value repository_cell.value&.formatted
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

json.icons do
  json.delimiter_path asset_path 'icon_small/navigate_next.svg'
  json.unlink_path asset_path 'icon_small/unlink.svg'
  json.notification_path asset_path 'icon_small/info.svg'
end
