json.team_details do
  json.id team.id
  json.created_at team.created_at
  json.created_by "#{team.created_by.full_name} (#{team.created_by.email})"
  json.space_taken team.space_taken
  json.description team.description
  json.users team_users do |team_user|
    json.id team_user.user.id
    json.email team_user.user.full_name
    json.role team_user.role_str
    json.created_at I18n.l(team_user.created_at, format: :full_date)
    json.status team_user.user.active_status_str
    json.actions do
      json.current_role team_user.role_str
      json.team_user_id team_user.id
    end
  end
end
