json.teams do
  json.collection teams do |team|
    json.id team.fetch('id')
    json.name team.fetch('name')
    json.members team.fetch('members')
    json.role UserTeam.roles.keys[team.fetch('role')]
    json.current_team team.fetch('current_team')
  end
end
