# users
get '/current_user_info', to: 'users/users#current_user_info'

namespace :users do
  get '/sign_out_user', to: 'users#sign_out_user'
  delete '/remove_user', to: 'user_teams#remove_user'
  delete '/leave_team', to: 'user_teams#leave_team'
  put '/update_role', to: 'user_teams#update_role'
  get '/profile_info', to: 'users#profile_info'
  get '/preferences_info', to: 'users#preferences_info'
  get '/statistics_info', to: 'users#statistics_info'
  post '/update', to: 'users#update'
  devise_scope :user do
    put '/invite_users', to: 'invitations#invite_users'
  end
end
