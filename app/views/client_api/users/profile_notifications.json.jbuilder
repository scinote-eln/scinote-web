json.user do
  json.notifications do
    json.assignments user.assignments_notification
    json.assignments_email user.assignments_email_notification
    json.recent user.recent_notification
    json.recent_email user.recent_email_notification
    json.system_message_email user.system_message_email_notification
  end
end
