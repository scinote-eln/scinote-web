# users
get '/current_user_info', to: 'users/users#current_user_info'

namespace :users do
  delete '/remove_user', to: 'user_teams#remove_user'
  delete '/leave_team', to: 'user_teams#leave_team'
  put '/update_role', to: 'user_teams#update_role'
  get '/profile_info', to: 'users#profile_info'
  get '/statistics_info', to: 'users#statistics_info'
  get '/preferences_info', to: 'users#preferences_info'
  delete '/leave_team', to: 'user_teams#leave_team'
  post '/change_full_name', to: 'users#change_full_name'
  post '/change_initials', to: 'users#change_initials'
  post '/change_email', to: 'users#change_email'
  post '/change_password', to: 'users#change_password'
  post '/change_timezone', to: 'users#change_timezone'
  post '/change_assignements_notification',
       to: 'users#change_assignements_notification'
  post '/change_assignements_notification_email',
       to: 'users#change_assignements_notification_email'
  post '/change_recent_notification',
       to: 'users#change_recent_notification'
  post '/change_recent_notification_email',
       to: 'users#change_recent_notification_email'
  post '/change_system_notification_email',
       to: 'users#change_system_notification_email'
  devise_scope :user do
    put '/invite_users', to: 'invitations#invite_users'
  end
end
