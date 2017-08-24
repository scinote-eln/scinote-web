json.user do
  json.id user.id
  json.fullName user.full_name
  json.initials user.initials
  json.email user.email
  json.avatarPath avatar_path(user, :icon_small)
  json.avatarThumbPath avatar_path(user, :thumb)
  json.statistics user.statistics
  json.timezone user.time_zone
  json.assignmentsNotification user.assignments_notification
  json.assignmentsNotificationEmail user.assignments_notification_email
  json.recentNotification user.recent_notification
  json.recentNotificationEmail user.recent_notification_email
  json.systemMessageNotificationEmail user.system_message_notification_email
end
