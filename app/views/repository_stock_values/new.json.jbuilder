# frozen_string_literal: true

json.stock_url update_repository_stock_repository_repository_row_url(@repository, @repository_row)
json.repository_row_name @repository_row.name
json.stock_value do
  json.decimals @repository_column.metadata['decimals']
  json.units @repository_column.repository_stock_unit_items.pluck(:id, :data)
end
