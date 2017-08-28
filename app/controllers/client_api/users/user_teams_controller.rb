module ClientApi
  module Users
    class UserTeamsController < ApplicationController
      include NotificationsHelper
      include InputSanitizeHelper
      include ClientApi::Users::UserTeamsHelper

      before_action :find_user_team, only: :leave_team

      def leave_team
        if user_cant_leave
          unsuccess_response
        else
          begin
            assign_new_team_owner
            generate_new_notification
            success_response
          rescue
            unsuccess_response
          end
        end
      end

      private

      def find_user_team
        @team = Team.find_by_id(params[:team])
        @user_team = UserTeam.where(team: @team, user: current_user).first
      end

      def user_cant_leave
        @user_team.admin? &&
          @team.user_teams.where(role: 2).count <= 1
      end

      def success_response
        respond_to do |format|
          # return a list of teams
          format.json do
            render template: '/client_api/teams/index',
                   status: :ok,
                   locals: {
                     teams: current_user.teams_data,
                     flash_message: t('client_api.user_teams.leave_flash',
                                      team: @team.name)
                   }
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

      def assign_new_team_owner
        new_owner = @team.user_teams
                         .where(role: 2)
                         .where.not(id: @user_team.id)
                         .first.user
        new_owner ||= current_user
        reset_user_current_team(@user_team)
        @user_team.destroy(new_owner)
      end

      def reset_user_current_team(user_team)
        ids = user_team.user.teams_ids
        ids -= [user_team.team.id]
        user_team.user.current_team_id = ids.first
        user_team.user.save
      end

      def generate_new_notification
        generate_notification(@user_team.user, @user_team.user, @user_team.team,
                              false, false)
      end
    end
  end
end
