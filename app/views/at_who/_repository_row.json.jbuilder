json.id row[:id_encoded]
json.name row[:name]
json.code row[:code]
json.type 'rep_item'

if row.key?(:my_module_id)
  json.row_assigned row[:row_assigned]
  json.my_module_id row[:my_module_id]
  json.assign_url my_module_repositories_path(row[:my_module_id])
  json.repository_row_id row[:id]
end
