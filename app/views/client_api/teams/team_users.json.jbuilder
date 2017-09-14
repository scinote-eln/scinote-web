json.team_users team_users do |team_user|
  json.id team_user.user.id
  json.name team_user.user.full_name
  json.email team_user.user.email
  json.role team_user.role_str
  json.created_at I18n.l(team_user.created_at, format: :full_date)
  json.status team_user.user.active_status_str
  json.actions do
    json.current_role team_user.role_str
    json.team_user_id team_user.id
    json.disable team_user.user == current_user
  end
end
