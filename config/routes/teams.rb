# teams
get '/teams', to: 'teams/teams#index'

namespace :teams do
  get '/new', to: 'teams#new'
  get '/:team_id/details', to: 'teams#details'
  get '/current_team', to: 'teams#current_team'
  post '/', to: 'teams#create'
  post '/change_team', to: 'teams#change_team'
  post '/update', to: 'teams#update'
end
