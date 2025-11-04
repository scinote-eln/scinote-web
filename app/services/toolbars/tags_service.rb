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
      return unless can_delete_tags?(@team)

      {
        name: 'delete',
        label: I18n.t('tags.index.toolbar.delete'),
        icon: 'sn-icon sn-icon-delete',
        path: destroy_tags_team_tags_path(@team, tag_ids: @tags.pluck(:id)),
        type: :emit
      }
    end

    def merge_action
      return unless can_delete_tags?(@team) && can_create_tags?(@team)

      {
        name: 'merge',
        label: I18n.t('tags.index.toolbar.merge'),
        icon: 'sn-icon sn-icon-merge',
        type: :emit
      }
    end
  end
end
