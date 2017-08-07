json.global_activities do
  json.more more
  json.activities activities do |activity|
    json.id activity.id
    json.message activity.message
    json.created_at activity.created_at
  end
end
