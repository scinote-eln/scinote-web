json.user do
  json.id user.id
  json.fullName user.full_name
  json.initials user.initials
  json.email user.email
  json.avatarPath avatar_path(user, :icon_small)
  json.avatarThumbPath avatar_path(user, :thumb)
end
