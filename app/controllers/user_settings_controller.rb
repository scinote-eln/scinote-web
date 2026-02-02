# frozen_string_literal: true

class UserSettingsController < ApplicationController
  def show
    render json: { value: current_user.user_settings.select(:value).find_by!(key: params[:key]).value }
  end

  def update
    current_user.user_settings
                .find_or_create_by!(key: params[:key])
                .update!(value: user_setting_params[:value])

    head :ok
  end

  private

  def user_setting_params
    params.require(:user_setting).permit(value: {})
  end
end
