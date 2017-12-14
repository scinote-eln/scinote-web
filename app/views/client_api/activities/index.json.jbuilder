json.global_activities do
  json.more more
  json.currentPage page
  json.activities activities do |activity|
    json.id activity.id
    json.message activity.message
    json.createdAt activity.created_at
    json.timezone timezone
  end
end
