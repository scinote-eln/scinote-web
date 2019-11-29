module Users
  module Settings
    module Account
      class ConnectedAccountsController < ApplicationController
        layout 'fluid'

        def index
          @linked_accounts = current_user.user_identities.pluck(:provider)
        end

        def destroy
          current_user.user_identities.where(provider: params.require(:provider)).take&.destroy!
          @linked_accounts = current_user.user_identities.pluck(:provider)
          render :index
        end
      end
    end
  end
end
