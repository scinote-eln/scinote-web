json.teams do
  json.collection teams do |team|
    json.id team.fetch('id')
    json.name team.fetch('name')
    json.members team.fetch('members')
    json.role retrive_role_name(team.fetch('role') { nil })
    json.current_team team.fetch('current_team')
    json.can_be_left team.fetch('can_be_left')
    json.user_team_id team.fetch('user_team_id')
  end
end
