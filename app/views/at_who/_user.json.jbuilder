json.id user.id.base62_encode
json.full_name sanitize_input(user.full_name)
json.email user.email
json.avatar_url avatar_path(user, :icon_small)
