# frozen_string_literal: true

require 'rails_helper'

describe UserSettingsHelper, type: :helper do
  def on_page(controller_name, action_name = 'index')
    allow(helper).to receive(:controller_name).and_return(controller_name)
    allow(helper).to receive(:action_name).and_return(action_name)
  end

  describe '#on_settings_account_page?' do
    {
      %w(registrations edit) => true,
      %w(registrations show) => false,
      %w(preferences index) => true,
      %w(preferences show) => false,
      %w(addons index) => true,
      %w(addons show) => false,
      %w(connected_accounts show) => true,
      %w(projects index) => false
    }.each do |(controller, action), expected|
      it "returns #{expected} for #{controller}##{action}" do
        on_page(controller, action)

        expect(helper.on_settings_account_page?).to eq expected
      end
    end
  end

  describe '#on_settings_account_profile_page?' do
    it 'is true for the registrations controller only' do
      on_page('registrations', 'edit')
      expect(helper.on_settings_account_profile_page?).to be true

      on_page('preferences')
      expect(helper.on_settings_account_profile_page?).to be false
    end
  end

  describe '#on_settings_account_preferences_page?' do
    it 'is true for the preferences controller only' do
      on_page('preferences')
      expect(helper.on_settings_account_preferences_page?).to be true

      on_page('addons')
      expect(helper.on_settings_account_preferences_page?).to be false
    end
  end

  describe '#on_settings_account_addons_page?' do
    it 'is true for the addons controller' do
      on_page('addons')
      expect(helper.on_settings_account_addons_page?).to be true
    end

    it 'is true for the zebra label printers page' do
      on_page('label_printers', 'index_zebra')
      expect(helper.on_settings_account_addons_page?).to be true
    end

    it 'is false for other label printer actions' do
      on_page('label_printers', 'index')
      expect(helper.on_settings_account_addons_page?).to be false
    end
  end

  describe '#on_settings_team_page?' do
    it 'is true for team and audit pages with a listed action' do
      on_page('teams', 'show')
      expect(helper.on_settings_team_page?).to be true
      on_page('audits', 'audits_index')
      expect(helper.on_settings_team_page?).to be true
    end

    it 'is false for an unlisted action or another controller' do
      on_page('teams', 'destroy')
      expect(helper.on_settings_team_page?).to be false
      on_page('projects', 'index')
      expect(helper.on_settings_team_page?).to be false
    end
  end

  describe '#on_settings_webhook_page?' do
    it 'is true only for webhooks#index' do
      on_page('webhooks', 'index')
      expect(helper.on_settings_webhook_page?).to be true
      on_page('webhooks', 'new')
      expect(helper.on_settings_webhook_page?).to be false
    end
  end

  describe '#on_settings_account_connected_accounts_page?' do
    it 'is true only for the connected accounts controller' do
      on_page('connected_accounts')
      expect(helper.on_settings_account_connected_accounts_page?).to be true
      on_page('addons')
      expect(helper.on_settings_account_connected_accounts_page?).to be false
    end
  end
end
