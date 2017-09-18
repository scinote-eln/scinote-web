module ClientApi
  module Teams
    class TeamsController < ApplicationController
      include ClientApi::Users::UserTeamsHelper

      def index
        success_response('/client_api/teams/index',
                         teams: current_user.teams_data)
      end

      def details
        team_service = ClientApi::TeamsService.new(team_id: params[:team_id],
                                                   current_user: current_user)
        success_response('/client_api/teams/details',
                         team_service.team_page_details_data)
      rescue ClientApi::CustomTeamError
        error_response
      end

      def change_team
        team_service = ClientApi::TeamsService.new(team_id: params[:team_id],
                                                   current_user: current_user)
        team_service.change_current_team!
        success_response('/client_api/teams/index', team_service.teams_data)
      rescue ClientApi::CustomTeamError
        error_response
      end

      def update
        team_service = ClientApi::TeamsService.new(team_id: params[:team_id],
                                                   current_user: current_user,
                                                   params: team_params)
        team_service.update_team!
        success_response('/client_api/teams/update_details',
                         team_service.single_team_details_data)
      rescue ClientApi::CustomTeamError => error
        error_response(error.to_s)
      end

      private

      def team_params
        params.require(:team).permit(:description, :name)
      end

      def success_response(template, locals)
        respond_to do |format|
          format.json do
            render template: template,
                   status: :ok,
                   locals: locals
          end
        end
      end

      def error_response(message = t('client_api.generic_error_message'))
        respond_to do |format|
          format.json do
            render json: { message: message }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
