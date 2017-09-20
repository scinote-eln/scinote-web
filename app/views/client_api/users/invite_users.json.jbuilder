json.invite_results invite_results do |invite_result|
  json.status invite_result[:status]
  json.alert invite_result[:alert]
  json.email invite_result[:email]
  json.user_role invite_result[:user_team].role if invite_result[:user_team].present?
  json.invite_limit invite_result[:invite_user_limit] if invite_result[:invite_user_limit].present?
end
json.team_name team.name if team.present?