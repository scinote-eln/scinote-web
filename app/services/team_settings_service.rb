# frozen_string_literal: true

class TeamSettingPermissionError < StandardError; end

class TeamSettingsService
  include Canaid::Helpers::PermissionsHelper

  def initialize(team, user)
    @user = user
    @team = team
  end

  def available_settings
    @available_settings ||= Extends::AVAILABLE_TEAM_SETTINGS.to_h do |section, available_settings|
      [
        section,
        available_settings.to_h do |setting_key, setting|
          setting_params = {
            can_update: __send__(setting[:permission_helper], @user, @team),
            label: I18n.t("users.settings.teams.preferences.sections.#{section}.items.#{setting_key}.label"),
            value: @team.settings[setting_key.to_s] == true
          }

          if setting[:confirm]
            setting_params[:confirm] = {
              title: I18n.t("users.settings.teams.preferences.sections.#{section}.items.#{setting_key}.confirm.title"),
              description:
              I18n.t(
                "users.settings.teams.preferences.sections.#{section}.items.#{setting_key}.confirm.description",
                **setting[:confirm][:description_params].index_with { |attr_name| @team.__send__(attr_name) }
              ),
              button: I18n.t("users.settings.teams.preferences.sections.#{section}.items.#{setting_key}.confirm.button"),
            }
          end

          [setting_key, setting_params]
        end
      ]
    end
  end

  def update_setting!(section, key, value)
    raise ArgumentError, 'Value must be of type Boolean' unless value.in?([true, false])
    raise TeamSettingPermissionError unless can_update_setting?(section, key)

    @team.settings[key] = value
    @team.save!
  end

  private

  def can_update_setting?(section, key)
    available_settings[section.to_sym][key.to_sym][:can_update]
  end
end
