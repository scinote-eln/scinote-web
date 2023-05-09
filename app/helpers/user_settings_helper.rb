module UserSettingsHelper
  def on_settings_account_page?
    controller_name == 'registrations' && action_name == 'edit' ||
      controller_name == 'preferences' && action_name == 'index' ||
      controller_name == 'addons' && action_name == 'index' ||
      controller_name == 'connected_accounts'
  end

  def on_settings_account_profile_page?
    controller_name == 'registrations'
  end

  def on_settings_account_preferences_page?
    controller_name == 'preferences'
  end

  def on_settings_account_addons_page?
    controller_name == 'addons' ||
      (controller_name == 'label_printers' && action_name == 'index_zebra')
  end

  def on_settings_team_page?
    controller_name.in?(%w(teams audits)) &&
      action_name.in?(%w(index new create show audits_index))
  end

  def on_settings_webhook_page?
    controller_name.in?(%w(webhooks)) &&
      action_name.in?(%w(index))
  end

  def on_settings_account_connected_accounts_page?
    controller_name == 'connected_accounts'
  end
end
