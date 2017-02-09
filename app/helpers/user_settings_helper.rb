module UserSettingsHelper
  def on_settings_account_page?
    controller_name == 'registrations' && action_name == 'edit' ||
      controller_name == 'preferences' && action_name == 'index'
  end

  def on_settings_account_profile_page?
    controller_name == 'registrations'
  end

  def on_settings_account_preferences_page?
    controller_name == 'preferences'
  end

  def on_settings_team_page?
    controller_name == 'teams' &&
      action_name.in?(%w(index new create show))
  end
end
