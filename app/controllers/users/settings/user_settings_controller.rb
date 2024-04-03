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
          when 'task_step_states'
            update_task_step_states(data)
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

      def update_task_step_states(task_step_states_data)
        current_states = current_user.settings.fetch('task_step_states', {})

        task_step_states_data.each do |step_id, collapsed|
          if collapsed
            current_states[step_id] = true
          else
            current_states.delete(step_id)
          end
        end

        current_user.settings['task_step_states'] = current_states
      end
    end
  end
end
