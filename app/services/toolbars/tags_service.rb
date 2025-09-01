# frozen_string_literal: true

module Toolbars
  class TagsService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def initialize(current_user, team, tag_ids: [])
      @current_user = current_user
      @team = team
      @tags = team.tags.where(id: tag_ids)

      @single = @tags.length == 1
    end

    def actions
      return [] if @tags.none?

      [
        merge_action,
        delete_action
      ].compact
    end

    private

    def delete_action
      return unless @single

      #return unless can_manage_team?(@team)

      {
        name: 'delete',
        label: I18n.t('tags.index.toolbar.delete'),
        icon: 'sn-icon sn-icon-delete',
        path: users_settings_team_tag_path(@team, @tags.first),
        type: :emit
      }
    end

    def merge_action
      # return unless can_manage_team?(@team)

      {
        name: 'merge',
        label: I18n.t('tags.index.toolbar.merge'),
        icon: 'sn-icon sn-icon-merge',
        type: :emit
      }
    end
  end
end
