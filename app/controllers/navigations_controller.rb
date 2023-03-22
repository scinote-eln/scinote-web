# frozen_string_literal: true

class NavigationsController < ApplicationController
  include ApplicationHelper

  HELP_MENU_LINKS = [
    { name: I18n.t('left_menu_bar.support_links.support'), url: Constants::SUPPORT_URL },
    { name: I18n.t('left_menu_bar.support_links.tutorials'), url: Constants::TUTORIALS_URL },
    { name: I18n.t('left_menu_bar.academy'), url: Constants::ACADEMY_BL_LINK }
  ]

  SETTINGS_MENU_LINKS = [
    {
      name: I18n.t('users.settings.sidebar.teams'),
      url: Rails.application.routes.url_helpers.teams_path
    }, {
      name: I18n.t('users.settings.sidebar.account_nav.addons'),
      url: Rails.application.routes.url_helpers.addons_path
    }, {
      name: I18n.t('users.settings.sidebar.webhooks'),
      url: Rails.application.routes.url_helpers.users_settings_webhooks_path
    }
  ]

  USER_MENU_LINKS = [
    {
      name: I18n.t('users.settings.sidebar.account_nav.profile'),
      url: Rails.application.routes.url_helpers.edit_user_registration_path
    }, {
      name: I18n.t('users.settings.sidebar.account_nav.preferences'),
      url: Rails.application.routes.url_helpers.preferences_path
    }, {
      name: I18n.t('users.settings.sidebar.account_nav.connected_accounts'),
      url: Rails.application.routes.url_helpers.connected_accounts_path
    }
  ]

  def top_menu
    render json:  {
      root_url: root_path,
      logo: logo,
      current_team: current_team&.id,
      search_url: search_path,
      teams: teams,
      settings: [],
      help_menu: NavigationsController::HELP_MENU_LINKS,
      settings_menu: NavigationsController::SETTINGS_MENU_LINKS,
      user_menu: NavigationsController::USER_MENU_LINKS,
      user: user
    }
  end

  private

  def logo
    {
      large_url: image_path('/images/scinote_icon.svg'),
      small_url: image_path('/images/sn-icon.svg')
    }
  end

  def teams
    current_user.teams.order(:name).map do |t|
      {
        label: escape_input(t.name),
        value: t.id,
        params: { switch_url: switch_users_settings_team_path(t) }
      }
    end
  end

  def user
    {
      name: escape_input(current_user.full_name),
      avatar_url: avatar_path(current_user, :icon_small),
      sign_out_url: destroy_user_session_path
    }
  end
end
