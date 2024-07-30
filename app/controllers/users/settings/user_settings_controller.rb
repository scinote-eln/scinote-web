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

          next unless Extends::WHITELISTED_USER_SETTINGS.include?(key.to_s)

          case key.to_s
          when 'task_step_states', 'result_states'
            update_object_states(data, key.to_s)
          else
            current_user.settings[key] = data
          end
        end

        if current_user.save
          head :ok
        else
          render json: { error: 'Failed to update settings', details: current_user.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      private

      def update_object_states(object_states_data, object_state_key)
        current_states = current_user.settings.fetch(object_state_key, {})

        object_states_data.each do |object_id, collapsed|
          if collapsed
            current_states[object_id] = true
          else
            current_states.delete(object_id)
          end
        end

        current_user.settings[object_state_key] = current_states
      end
    end
  end
end
