# frozen_string_literal: true

json.stock_consumption @module_repository_row.stock_consumption
json.name @repository_row.name
json.unit @stock_value.repository_stock_unit_item&.data
json.formatted_stock_consumption @module_repository_row.formated_stock_consumption
json.decimals @stock_value.repository_cell.repository_column.metadata['decimals']
json.initial_stock @stock_value.amount
json.formatted_stock @stock_value.formatted_value
json.html @html_modal
json.update_url update_consumption_my_module_repository_path(@my_module, @repository, module_row_id: @module_repository_row)
