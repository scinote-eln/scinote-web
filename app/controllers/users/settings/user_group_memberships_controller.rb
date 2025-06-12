# frozen_string_literal: true

module Users
  module Settings
    class UserGroupMembershipsController < ApplicationController
      before_action :load_team, except: :index
      before_action :load_user_group
      before_action :check_manage_permissions, except: %i(index show)

      def index; end

      def show; end

      def create; end

      def destroy; end

      private

      def load_team
        @team = Team.find(params[:team_id])
      end

      def load_user_group
        @user_group = @team.user_groups.find(params[:user_group_id])
      end

      def load_user_group
        @user_group_membership = @user_group.user_group_memberships.find(params[:id])
      end

      def check_manage_permissions
        render_403 unless can_manage_team(@team)
      end
    end
  end
end
