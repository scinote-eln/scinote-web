# frozen_string_literal: true

module Users
  module Settings
    class TagsController < ApplicationController
      before_action :load_team
      before_action :check_team_permissions
      before_action :set_breadcrumbs_items, only: %i(index)

      def index
        respond_to do |format|
          format.html do
            @active_tab = :tags
          end
          format.json do
            tags = Lists::TagsService.new(@team.tags, params).call
            render json: tags, each_serializer: Lists::TagSerializer, user: current_user, meta: pagination_dict(tags)
          end
        end
      end

      def actions_toolbar
        render json: {
          actions:
            Toolbars::TagsService.new(
              current_user,
              @team,
              tag_ids: JSON.parse(params[:items]).pluck('id')
            ).actions
        }
      end

      private

      def load_team
        @team = current_user.teams.find_by(id: params[:team_id])
        render_404 unless @team
      end

      def check_team_permissions
        render_403 unless can_delete_tags?(@team) # Only team admin can access tags settings
      end

      def set_breadcrumbs_items
        @breadcrumbs_items = [
          { label: t('breadcrumbs.teams'), url: teams_path },
          { label: @team.name, url: team_path(@team) }
        ]
      end
    end
  end
end
