json.user do
  json.notifications do
    json.assignments user.assignments_notification
    json.assignments_email user.assignments_notification_email
    json.recent user.recent_notification
    json.recent_email user.recent_notification_email
    json.system_message_email user.system_message_notification_email
  end
end
