json.user do
  json.timeZone user.time_zone
  json.notifications do
    json.assignmentsNotification user.assignments_notification
    json.assignmentsNotificationEmail user.assignments_notification_email
    json.recentNotification user.recent_notification
    json.recentNotificationEmail user.recent_notification_email
    json.systemMessageNofificationEmail user.system_message_notification_email
  end
end
