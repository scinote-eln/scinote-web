json.global_activities do
  json.more more
  json.currentPage page
  json.activities activities do |activity|
    json.id activity.id
    json.message activity.message
    json.createdAt activity.created_at
    json.timezone timezone
    if activity.my_module
      json.project activity.my_module.experiment.project.name
      json.task activity.my_module.name
    end
  end
end
