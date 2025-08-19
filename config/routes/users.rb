# users
get '/current_user_info', to: 'users/users#current_user_info'

namespace :users do
  get '/sign_out_user', to: 'users#sign_out_user'
  get '/profile_info', to: 'users#profile_info'
  get '/preferences_info', to: 'users#preferences_info'
  get '/statistics_info', to: 'users#statistics_info'
  post '/update', to: 'users#update'
  devise_scope :user do
    put '/invite_users', to: 'invitations#invite_users'
  end
end
