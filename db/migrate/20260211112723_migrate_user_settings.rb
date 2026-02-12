# frozen_string_literal: true

class MigrateUserSettings < ActiveRecord::Migration[7.2]

  def up
    User.find_each do |user|

      current_settings = user.settings

      ['notifications_settings',
       'task_step_states',
       'results_order',
       'result_states',
       'result_templates_order',
       'result_template_states'].each do |setting_key|
        next unless current_settings[setting_key].present?
        user.user_settings.create!(
          key: setting_key,
          value: current_settings[setting_key]
        )

        current_settings.delete(setting_key)
      end

      user.user_settings.create!(
        key: 'navigator_state',
        value: {
          collapsed: current_settings['navigator_collapsed'] || false,
          width: current_settings['navigator_width']
        }
      )

      current_settings.delete('navigator_collapsed') if current_settings.key?('navigator_collapsed')
      current_settings.delete('navigator_width') if current_settings.key?('navigator_width')

      # rubocop:disable Rails/SkipsModelValidations
      user.update_column(:settings, current_settings)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def down
    User.find_each do |user|
      user.user_settings.where(key: [
        'notifications_settings',
        'task_step_states',
        'results_order',
        'result_template_states',
        'result_templates_order',
        'result_states',
        'navigator_state',
      ]).each do |setting|
        if setting.key == 'navigator_state'
          user.settings['navigator_collapsed'] = setting.value['collapsed']
          user.settings['navigator_width'] = setting.value['width']
        else
          user.settings[setting.key] = setting.value
        end

        setting.destroy
      end

      # rubocop:disable Rails/SkipsModelValidations
      user.update_column(:settings, user.settings)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
