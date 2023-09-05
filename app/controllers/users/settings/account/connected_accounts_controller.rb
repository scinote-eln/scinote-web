module Users
  module Settings
    module Account
      class ConnectedAccountsController < ApplicationController
        layout 'fluid'

        def index
          @linked_accounts = current_user.user_identities.pluck(:provider)
        end

        def destroy
          user_identity = current_user.user_identities.find_by(provider: params[:provider])
          if user_identity.blank?
            flash.now[:error] = t('users.settings.account.connected_accounts.errors.not_found')
            return
          end
          user_identity.destroy!
          flash.now[:success] = t('users.settings.account.connected_accounts.unlink_success')
        rescue StandardError
          flash.now[:error] ||= t('users.settings.account.connected_accounts.errors.generic')
        ensure
          @linked_accounts = current_user.user_identities.pluck(:provider)
          render :index
        end
      end
    end
  end
end
