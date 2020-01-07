module Users
  module Settings
    module Account
      class ConnectedAccountsController < ApplicationController
        layout 'fluid'

        def index
          @linked_accounts = current_user.user_identities.pluck(:provider)
        end

        def destroy
          if Rails.configuration.x.azure_ad_apps.select { |_, v| v[:provider] == params[:provider] }.present?
            provider = params[:provider]
          else
            flash[:error] = t('users.settings.account.connected_accounts.errors.not_found')
            return
          end
          ActiveRecord::Base.transaction do
            __send__("#{provider}_pre_destroy".to_sym) if respond_to?("#{provider}_pre_destroy".to_sym, true)
            current_user.user_identities.where(provider: provider).take&.destroy!
          end
          flash[:success] = t('users.settings.account.connected_accounts.unlink_success')
        rescue StandardError
          flash[:error] ||= t('users.settings.account.connected_accounts.errors.generic')
        ensure
          @linked_accounts = current_user.user_identities.pluck(:provider)
          render :index
        end
      end
    end
  end
end
