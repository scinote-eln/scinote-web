# frozen_string_literal: true

module Users
  module Settings
    class UserGroupsController < ApplicationController
      before_action :load_team
      before_action :load_user_group, except: :index
      before_action :check_manage_permissions, except: %i(index show)
      before_action :set_breadcrumbs_items

      def index
        @active_tab = :user_groups
      end

      def show; end

      def create; end

      def destroy; end

      private

      def load_team
        @team = Team.find(params[:team_id])
      end

      def load_user_group
        @user_group = @team.user_groups.find(params[:id])
      end

      def check_manage_permissions
        render_403 unless can_manage_team(@team)
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
