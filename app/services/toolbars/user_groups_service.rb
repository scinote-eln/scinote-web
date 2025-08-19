# frozen_string_literal: true

module Toolbars
  class UserGroupsService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def initialize(current_user, team, user_group_ids: [])
      @current_user = current_user
      @team = team
      @user_groups = team.user_groups.where(id: user_group_ids)

      @single = @user_groups.length == 1
    end

    def actions
      return [] if @user_groups.none?

      [
        delete_action
      ].compact
    end

    private

    def delete_action
      return unless @single

      return unless can_manage_team?(@team)

      {
        name: 'delete',
        label: I18n.t('user_groups.index.toolbar.delete'),
        icon: 'sn-icon sn-icon-delete',
        path: users_settings_team_user_group_path(@team, @user_groups.first),
        type: :emit
      }
    end
  end
end
