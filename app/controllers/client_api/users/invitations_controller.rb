module ClientApi
  module Users
    class InvitationsController < Devise::InvitationsController
      before_action :check_invite_users_permission, only: :invite_users

      def invite_users
        invite_service =
          ClientApi::InvitationsService.new(user: current_user,
                                            team: @team,
                                            role: params['user_role'],
                                            emails: params[:emails])
        invite_results = invite_service.invitation
        success_response(invite_results)
      rescue => error
        respond_to do |format|
          format.json do
            render json: { message: error }, status: :unprocessable_entity
          end
        end
      end

      private

      def success_response(invite_results)
        respond_to do |format|
          format.json do
            render template: '/client_api/users/invite_users',
                   status: :ok,
                   locals: { invite_results: invite_results, team: @team }
          end
        end
      end

      def check_invite_users_permission
        @team = Team.find_by_id(params[:team_id])
        if @team && !can_manage_team_users?(@team)
          respond_422(t('client_api.invite_users.permission_error'))
        end
      end
    end
  end
end
