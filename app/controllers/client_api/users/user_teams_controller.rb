module ClientApi
  module Users
    class UserTeamsController < ApplicationController
      include ClientApi::Users::UserTeamsHelper

      before_action :find_user_team, only: :leave_team

      def leave_team
        user_team_service = ClientApi::UserTeamService.new(user: current_user)
        user_team_service.destroy_user_team_and_assign_new_team_owner!
        success_response(user_team_service.teams_data)
      rescue
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
