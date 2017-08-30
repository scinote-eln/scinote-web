json.team_details do
  json.id team.id
  json.created_at team.created_at
  json.created_by team.created_by
  json.space_taken team.space_taken
  json.description team.description
  json.users users do |user|
    # json.id team.fetch('id')
    # json.name team.fetch('name')
    # json.members team.fetch('members')
    # json.role retrive_role_name(team.fetch('role') { nil })
    # json.current_team team.fetch('current_team')
    # json.can_be_leaved team.fetch('can_be_leaved')
  end
end
