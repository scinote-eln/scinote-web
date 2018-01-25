json.array! notifications do |notification|
  json.id notification.id
  json.title notification.title
  json.message notification.message
  json.typeOf notification.type_of
  json.createdAt notification.created_at
  if notification.type_of == 'recent_changes'
    json.avatarThumb avatar_path(notification.generator_user, :icon_small)
  end
end
