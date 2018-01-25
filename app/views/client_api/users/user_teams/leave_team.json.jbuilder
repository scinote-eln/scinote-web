json.teams do
  json.flash_message flash_message
  json.collection teams do |team|
    json.id team.fetch('id')
    json.name team.fetch('name')
    json.members team.fetch('members')
    json.role json.role retrive_role_name(team.fetch('role') { nil })
    json.current_team team.fetch('current_team')
    json.can_be_left team.fetch('can_be_left')
  end
end
