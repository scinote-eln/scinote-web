module ClientApi
  module Users
    class UserTeamsController < ApplicationController
      include ClientApi::Users::UserTeamsHelper

      before_action :check_leave_team_permission, only: :leave_team
      before_action :check_manage_user_team_permission,
                    only: %i(update_role remove_user)

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

      def check_leave_team_permission
        return unless params[:user_team]
        user_team = UserTeam.find_by_id(params[:user_team])
        unless current_user == user_team.user || can_read_team?(user_team.team)
          respond_422(t('client_api.permission_error'))
        end
      end

      def check_manage_user_team_permission
        user_team = UserTeam.find_by_id(params[:user_team])
        unless can_manage_team_users?(user_team.team)
          respond_422(t('client_api.user_teams.permission_error'))
        end
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
