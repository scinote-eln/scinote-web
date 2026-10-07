json.id item[:id]
json.id_encoded item[:id_encoded]
json.name item[:name]
json.code item[:code]
json.type item[:type]

if item.key?(:my_module_id)
  json.row_assigned item[:row_assigned]
  json.my_module_id item[:my_module_id]
  json.repository_row_id item[:repository_row_id]
end
