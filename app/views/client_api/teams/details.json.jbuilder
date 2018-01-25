json.team_details do
  json.team do
    json.id team.id
    json.name team.name
    json.created_at team.created_at
    json.created_by "#{team.created_by.full_name} (#{team.created_by.email})"
    json.space_taken team.space_taken
    json.description team.description
  end
  json.users team_users do |team_user|
    json.id team_user.user.id
    json.name team_user.user.full_name
    json.email team_user.user.email
    json.role team_user.role_str
    json.created_at I18n.l(team_user.created_at, format: :full_date)
    json.status team_user.user.active_status_str
    json.actions do
      json.currentRole team_user.role_str
      json.teamUserId team_user.id
      json.disable team_user.user == current_user
    end
  end
end
