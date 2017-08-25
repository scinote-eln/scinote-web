module ClientApi
  module Users
    class UsersController < ApplicationController

      def current_user_info
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
