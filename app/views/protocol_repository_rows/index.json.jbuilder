# frozen_string_literal: true

json.data do
  json.array! @protocol_repository_rows do |protocol_repository_row|
    json.id protocol_repository_row.id
    json.repository_row_id protocol_repository_row.repository_row.id
    json.repository_row_name protocol_repository_row.repository_row.name
    json.repository_name protocol_repository_row.repository_row.repository.name
  end
end
json.recordsTotal @protocol_repository_rows.count
