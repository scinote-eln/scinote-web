# notifications
get '/recent_notifications', to: 'notifications#recent_notifications'
get '/unread_notifications_count',
    to: 'notifications#unread_notifications_count'
