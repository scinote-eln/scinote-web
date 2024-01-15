# frozen_string_literal: true

module Users
  module Settings
    class UserSettingsController < ApplicationController
      def show
        render json: { data: current_user.settings[params[:key]] }
      end

      def update
        settings_params = params.require(:settings)

        settings_params.each do |setting|
          key = setting[:key]
          data = setting[:data]

          current_user.settings[key] = data if Extends::WHITELISTED_USER_SETTINGS.include?(key.to_s)
        end

        if current_user.save
          head :ok
        else
          render json: { error: 'Failed to update settings', details: current_user.errors.full_messages },
                 status: :unprocessable_entity
        end
      end
    end
  end
end
