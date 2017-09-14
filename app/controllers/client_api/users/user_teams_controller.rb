module ClientApi
  module Users
    class UserTeamsController < ApplicationController
      include ClientApi::Users::UserTeamsHelper

      def leave_team
        ut_service = ClientApi::UserTeamService.new(
          user: current_user,
          team_id: params[:team],
          user_team_id: params[:user_team]
        )
        ut_service.destroy_user_team_and_assign_new_team_owner!
        success_response('/client_api/teams/index', ut_service.teams_data)
      rescue ClientApi::CustomUserTeamError
        unsuccess_response(t('client_api.user_teams.leave_team_error'))
      end

      def update_role
        ut_service = ClientApi::UserTeamService.new(
          user: current_user,
          team_id: params[:team],
          user_team_id: params[:user_team],
          role: params[:role]
        )
        ut_service.update_role!
        success_response('/client_api/teams/team_users',
                         ut_service.team_users_data)
      rescue ClientApi::CustomUserTeamError => error
        unsuccess_response(error.to_s)
      end

      def remove_user
        ut_service = ClientApi::UserTeamService.new(
          user: current_user,
          team_id: params[:team],
          user_team_id: params[:user_team]
        )
        ut_service.destroy_user_team_and_assign_new_team_owner!
        success_response('/client_api/teams/team_users',
                         ut_service.team_users_data)
      rescue ClientApi::CustomUserTeamError => error
        unsuccess_response(error.to_s)
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

      def unsuccess_response(message)
        respond_to do |format|
          format.json do
            render json: { message: message },
            status: :unprocessable_entity
          end
        end
      end
    end
  end
end
