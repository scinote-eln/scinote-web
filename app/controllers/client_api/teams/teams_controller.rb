module ClientApi
  module Teams
    class TeamsController < ApplicationController
      include ClientApi::Users::UserTeamsHelper

      before_action :check_update_team_permission, only: :update
      before_action :check_create_team_permission, only: :create

      def index
        teams = current_user.datatables_teams
        success_response(template: '/client_api/teams/index',
                         locals: { teams: teams })
      end

      def create
        service = ClientApi::Teams::CreateService.new(
          current_user: current_user,
          params: team_params
        )
        result = service.execute

        if result[:status] == :success
          success_response(details: { id: service.team.id })
        else
          error_response(
            message: result[:message],
            details: service.team.errors
          )
        end
      end

      def details
        teams_service = ClientApi::TeamsService.new(team_id: params[:team_id],
                                                   current_user: current_user)
        success_response(template: '/client_api/teams/details',
                         locals: teams_service.team_page_details_data)
      rescue ClientApi::CustomTeamError
        error_response
      end

      def change_team
        teams_service = ClientApi::TeamsService.new(team_id: params[:team_id],
                                                   current_user: current_user)
        teams_service.change_current_team!
        success_response(template: '/client_api/teams/index',
                         locals: teams_service.teams_data)
      rescue ClientApi::CustomTeamError
        error_response
      end

      def update
        teams_service = ClientApi::TeamsService.new(team_id: params[:team_id],
                                                   current_user: current_user,
                                                   params: team_params)
        teams_service.update_team!
        success_response(template: '/client_api/teams/update_details',
                         locals: teams_service.single_team_details_data)
      rescue ClientApi::CustomTeamError => error
        error_response(message: error.to_s)
      end

      def current_team
        success_response(template: '/client_api/teams/current_team',
                         locals: { team: current_user.current_team })
      end

      private

      def team_params
        params.require(:team).permit(:name, :description)
      end

      def check_create_team_permission
        unless can_create_teams?
          respond_422(t('client_api.teams.create_permission_error'))
        end
      end

      def check_update_team_permission
        @team = Team.find_by_id(params[:team_id])
        unless can_update_team?(@team)
          respond_422(t('client_api.teams.update_permission_error'))
        end
      end

      def success_response(args = {})
        template = args.fetch(:template) { nil }
        locals = args.fetch(:locals) { {} }
        details = args.fetch(:details) { {} }

        respond_to do |format|
          format.json do
            if template
              render template: template,
                     status: :ok,
                     locals: locals
            else
              render json: { details: details }, status: :ok
            end
          end
        end
      end

      def error_response(args = {})
        message = args.fetch(:message) { t('client_api.generic_error_message') }
        details = args.fetch(:details) { {} }
        status = args.fetch(:status) { :unprocessable_entity }

        respond_to do |format|
          format.json do
            render json: {
              message: message,
              details: details
            },
            status: status
          end
        end
      end
    end
  end
end
