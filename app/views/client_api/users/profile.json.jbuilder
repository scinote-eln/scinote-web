json.user do
  json.full_name user.full_name
  json.initials user.initials
  json.email user.email
  json.avatar_thumb_path avatar_path(user, :thumb)
  json.time_zone user.time_zone
end
