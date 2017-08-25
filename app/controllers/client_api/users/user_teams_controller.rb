module ClientApi
  module Users
    class UserTeamsController < ApplicationController

      def leave_team
        byebug
        respond_to do |format|
          format.json do
            render template: '/client_api/users/show',
                   status: :ok,
                   locals: { user: current_user }
          end
        end
      end
    end
  end
end
