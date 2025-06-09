# frozen_string_literal: true

module Users
  module Settings
    class UserGroupsController < ApplicationController
      before_action :load_team
      before_action :set_breadcrumbs_items

      def index
        @active_tab = :user_groups
      end

      private

      def load_team
        @team = Team.find_by(id: params[:team_id])
        render_403 unless can_manage_team?(@team)
      end

      def set_breadcrumbs_items
        @breadcrumbs_items = []

        @breadcrumbs_items.push({
                                  label: t('breadcrumbs.teams'),
                                  url: teams_path
                                })
        if @team
          @breadcrumbs_items.push({
                                    label: @team.name,
                                    url: team_path(@team)
                                  })
        end
      end
    end
  end
end
