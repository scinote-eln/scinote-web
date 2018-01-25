json.team do
  json.id team.id
  json.name team.name
  json.created_at team.created_at
  json.created_by "#{team.created_by.full_name} (#{team.created_by.email})"
  json.space_taken team.space_taken
  json.description team.description
end
