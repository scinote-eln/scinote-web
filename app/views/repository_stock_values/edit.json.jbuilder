# frozen_string_literal: true

json.stock_url update_repository_stock_repository_repository_row_url(@repository, @repository_row)
json.repository_row_name @repository_row.name
json.stock_value do
  json.id @repository_stock_value.id
  json.amount @repository_stock_value.formatted_value
  json.decimals @repository_column.metadata['decimals']
  json.units @repository_column.repository_stock_unit_items.pluck(:id, :data)
  json.unit @repository_stock_value.repository_stock_unit_item_id
  json.reminder_enabled @repository_stock_value.low_stock_threshold.present?
  json.low_stock_treshold @repository_stock_value.formatted_treshold
end
