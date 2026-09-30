json.items do
  json.array! @rows do |row|
    json.partial! 'repository_row', row: row
  end
end

json.limit_reached @limit_reached
json.repository @repository_id
json.team @team_id
