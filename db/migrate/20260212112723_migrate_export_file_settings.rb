# frozen_string_literal: true

class MigrateExportFileSettings < ActiveRecord::Migration[7.2]

  def up
    User.find_each do |user|

      current_settings = user.settings

      if current_settings['repository_export_file_type'].present?
        user.user_settings.create!(
          key: 'repository_export_file_type',
          value: current_settings['repository_export_file_type']
        )

        current_settings.delete('repository_export_file_type')
      end

      # rubocop:disable Rails/SkipsModelValidations
      user.update_column(:settings, current_settings)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def down
    User.find_each do |user|

      export_file_type_setting = user.user_settings.find_by(key: 'repository_export_file_type')

      if export_file_type_setting.present?
        current_settings = user.settings
        current_settings['repository_export_file_type'] = export_file_type_setting.value

        # rubocop:disable Rails/SkipsModelValidations
        user.update_column(:settings, current_settings)
        # rubocop:enable Rails/SkipsModelValidations

        export_file_type_setting.destroy!
      end
    end
  end
end
