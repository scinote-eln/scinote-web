# frozen_string_literal: true

class NavigationsController < ApplicationController
  include ApplicationHelper

  def top_menu
    render json:  {
      root_url: root_path,
      logo: logo,
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
        label: t.name,
        value: t.id,
        params: { switch_url: switch_users_settings_team_path(t) }
      }
    end
  end

  def user
    {
      name: current_user.full_name,
      avatar_url: avatar_path(current_user, :icon_small),
      sign_out_url: destroy_user_session_path
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
      }, {
        name: I18n.t('users.settings.sidebar.webhooks'), url: users_settings_webhooks_path
      }
    ]

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
