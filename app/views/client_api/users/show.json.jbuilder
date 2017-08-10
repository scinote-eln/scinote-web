json.user do
  json.id user.id
  json.fullName user.full_name
  json.avatarPath avatar_path(user, :icon_small)
  json.avatarThumbPath avatar_path(user, :thumb)
end
