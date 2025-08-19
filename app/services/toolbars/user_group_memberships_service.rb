# frozen_string_literal: true

module Toolbars
  class UserGroupMembershipsService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def initialize(current_user, user_group, user_group_membership_ids: [])
      @current_user = current_user
      @user_group = user_group
      @team = user_group.team
      @memberships = @user_group.user_group_memberships.where(id: user_group_membership_ids)

      @single = @memberships.length == 1
    end

    def actions
      return [] if @memberships.none?

      [
        delete_action
      ].compact
    end

    private

    def delete_action
      return unless can_manage_team?(@team)

      {
        name: 'delete',
        label: 'Remove',
        icon: 'sn-icon sn-icon-close',
        path: destroy_multiple_users_settings_team_user_group_user_group_memberships_path(@team, @user_group, membership_ids: @memberships.pluck(:id)),
        type: :emit
      }
    end
  end
end
