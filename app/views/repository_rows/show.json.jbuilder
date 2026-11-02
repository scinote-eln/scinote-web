# frozen_string_literal: true

json.id @repository_row.id
if @repository_row.snapshot_at
  json.snapshot_at DateTime.parse(@repository_row.snapshot_at).strftime("#{I18n.backend.date_format} %H:%M")
  json.snapshot_by_name @repository_row.snapshot_by_name
end

json.repository do
  json.id @repository.id
  json.name @repository.name
  json.is_snapshot @repository.is_a?(RepositorySnapshot) || !@repository_row.snapshot_at.nil?
  json.url repository_path(@repository)
end
json.editable @repository_row.editable?
json.notification @notification

json.permissions do
  json.can_export_repository_stock @repository_row.snapshot_at.nil? && can_export_repository_stock?(@repository)
  json.can_manage @repository_row.snapshot_at.nil? && can_manage_repository_rows?(@repository) if @repository.is_a?(Repository) && !@repository.is_a?(SoftLockedRepository)
  json.can_connect_rows @repository_row.snapshot_at.nil? && can_connect_repository_rows?(@repository) if @repository.is_a?(Repository) && !@repository.is_a?(SoftLockedRepository)
end

json.equipment_booking do
  json.enabled Repository.equipment_booking_enabled?
  json.placeholder equipment_booking_placeholder
end

json.row @row

json.assign_to_current_task @assign_to_current_task

json.column_defs @column_defs

json.custom_columns_preview @repository_row.repository_cells.select { |cell| cell.value.present? }.map { |cell|
  { id: cell.repository_column_id, name: cell.repository_column.name, formatted_value: cell.value&.formatted }
}

json.icons do
  json.delimiter_path asset_path 'icon_small/navigate_next.svg'
  json.unlink_path asset_path 'icon_small/unlink.svg'
  json.notification_path asset_path 'icon_small/info.svg'
end
