module ClientApi
  module Users
    class UserTeamsController < ApplicationController
      include ClientApi::Users::UserTeamsHelper

      def leave_team
        ut_service = ClientApi::UserTeamService.new(user: current_user,
                                                    team_id: params[:team],
                                                    user_team_id: params[:user_team])
        ut_service.destroy_user_team_and_assign_new_team_owner!
        success_response(ut_service.teams_data)
      rescue ClientApi::CustomUserTeamError
        unsuccess_response
      end

      def update_role

      end

      private

      def success_response(locals)
        respond_to do |format|
          # return a list of teams
          format.json do
            render template: '/client_api/teams/index',
                   status: :ok,
                   locals: locals
          end
        end
      end

      def unsuccess_response
        respond_to do |format|
          format.json do
            render json: { message: t(
              'client_api.user_teams.leave_team_error'
            ) },
            status: :unprocessable_entity
          end
        end
      end
    end
  end
end
