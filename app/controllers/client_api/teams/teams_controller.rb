module ClientApi
  module Teams
    class TeamsController < ApplicationController
      include ClientApi::Users::UserTeamsHelper

      def index
        success_response('/client_api/teams/index',
                         teams: current_user.teams_data)
      end

      def details
        team_service = ClientApi::TeamsService.new(id: params[:team_id],
                                                   current_user: current_user)
        success_response('/client_api/teams/details',
                         team_service.team_page_details_data)
      rescue MissingTeamError
        error_response
      end

      def change_team
        team_service = ClientApi::TeamsService.new(id: params[:team_id],
                                                   current_user: current_user)
        team_service.change_current_team!
        success_response('/client_api/teams/index', team_service.teams_data)
      rescue MissingTeamError
        error_response
      end

      private

      def success_response(template, locals)
        respond_to do |format|
          format.json do
            render template: template,
                   status: :ok,
                   locals: locals
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
    end
  end
end
