json.array! teams do |team|
  json.id team.id
  json.name team.name
  json.current_team team == current_user.current_team
end
