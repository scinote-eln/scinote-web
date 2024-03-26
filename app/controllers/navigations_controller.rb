# frozen_string_literal: true

class NavigationsController < ApplicationController
  include ApplicationHelper

  def top_menu
    render json:  {
      root_url: root_path,
      team_switch_url: switch_users_settings_teams_path,
      current_team: current_team&.id,
      search_url: search_path,
      teams: teams,
      settings: [],
      help_menu: help_menu_links,
      settings_menu: settings_menu_links,
      user_menu: user_menu_links,
      user: user
    }
  end

  def navigator_state
    session[:navigator_collapsed] = params[:state] == 'collapsed'

    width = params[:width].to_i
    session[:navigator_width] = width if width.positive?
  end

  private

  def teams
    current_user.teams.order(:name).map do |t|
      [
        t.id,
        t.name
      ]
    end
  end

  def user
    {
      name: current_user.full_name,
      avatar_url: avatar_path(current_user, :icon_small),
      sign_out_url: destroy_user_session_path,
      preferences_url: preferences_url
    }
  end

  def help_menu_links
    links = [
      { name: I18n.t('left_menu_bar.support_links.support'), url: Constants::SUPPORT_URL },
      { name: I18n.t('left_menu_bar.support_links.tutorials'), url: Constants::TUTORIALS_URL },
      { name: I18n.t('left_menu_bar.academy'), url: Constants::ACADEMY_BL_LINK }
    ]

    private_methods.select { |i| i.to_s[/^help_menu_links_[a-z]*_extension$/] }.each do |method|
      links = __send__(method, links)
    end

    links
  end

  def settings_menu_links
    links = [
      {
        name: I18n.t('users.settings.sidebar.teams'), url: teams_path
      }, {
        name: I18n.t('users.settings.sidebar.account_nav.addons'), url: addons_path
      }
    ]

    if can_create_acitivity_filters?
      links.push({ name: I18n.t('users.settings.sidebar.webhooks'), url: users_settings_webhooks_path })
    end

    private_methods.select { |i| i.to_s[/^settings_menu_links_[a-z]*_extension$/] }.each do |method|
      links = __send__(method, links)
    end

    links
  end

  def user_menu_links
    links = [
      {
        name: I18n.t('users.settings.sidebar.account_nav.profile'), url: edit_user_registration_path
      }, {
        name: I18n.t('users.settings.sidebar.account_nav.preferences'), url: preferences_path
      }, {
        name: I18n.t('users.settings.sidebar.account_nav.connected_accounts'), url: connected_accounts_path
      }
    ]

    private_methods.select { |i| i.to_s[/^user_menu_links_[a-z]*_extension$/] }.each do |method|
      links = __send__(method, links)
    end

    links
  end
end
