json.invite_results invite_results do |invite_result|
  json.status invite_result[:status]
  json.alert invite_result[:alert]
  json.email invite_result[:email]
  if invite_result[:user_team].present?
    json.user_role invite_result[:user_team].role
  end
  if invite_result[:invite_user_limit].present?
    json.invite_limit invite_result[:invite_user_limit]
  end
end
json.team_name team.name if team.present?
