json.array! notifications do |notification|
  json.id notification.id
  json.title notification.title
  json.message notification.message
  json.type_of notification.type_of
  json.created_at notification.created_at
end
