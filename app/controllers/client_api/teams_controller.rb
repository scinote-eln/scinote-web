module ClientApi
  class TeamsController < ApplicationController
    MissingTeamError = Class.new(StandardError)

    def index
      success_response
    end

    def change_team
      change_current_team
      success_response
    rescue MissingTeamError
      error_response
    end

    private

    def success_response
      respond_to do |format|
        format.json do
          render template: '/client_api/teams/index',
                 status: :ok,
                 locals: teams
        end
      end
    end

    def error_response
      respond_to do |format|
        format.json do
          render json: { message: 'Bad boy!' }, status: :bad_request
        end
      end
    end

    def teams
      { teams: current_user.teams_data }
    end

    def change_current_team
      team_id = params.fetch(:team_id) { raise MissingTeamError }
      unless current_user.teams.pluck(:id).include? team_id
        raise MissingTeamError
      end
      current_user.update_attribute(:current_team_id, team_id)
    end

  end
end
