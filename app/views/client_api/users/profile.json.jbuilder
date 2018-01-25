json.user do
  json.fullName user.full_name
  json.initials user.initials
  json.email user.email
  json.avatarThumb avatar_path(user, :thumb)
  json.timeZone user.time_zone
end
