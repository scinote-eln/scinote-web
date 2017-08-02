json.array! activities do |activity|
  json.id activity.id
  json.message activity.message
  json.created_at activity.created_at
end
