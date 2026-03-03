# frozen_string_literal: true

class UserSettingsController < ApplicationController
  def show
    render json: { value: current_user.user_settings.select(:value).find_by!(key: params[:key]).value }
  end

  def update
    state = current_user.user_settings.find_or_initialize_by(key: params[:key])
    value = if %w(result_states task_step_states result_template_states).include?(params[:key])
              update_object_states(user_setting_params[:value], state)
            else
              user_setting_params[:value]
            end

    state.update!(value: value)

    head :ok
  end

  private

  def user_setting_params
    params.require(:user_setting).permit(value: {})
  end

  def update_object_states(values, state)
    current_states = state.value || {}

    values.each do |object_id, collapsed|
      if collapsed
        current_states[object_id] = true
      else
        current_states.delete(object_id)
      end
    end

    current_states
  end
end
