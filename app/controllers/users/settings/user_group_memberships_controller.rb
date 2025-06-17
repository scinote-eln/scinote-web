# frozen_string_literal: true

module Users
  module Settings
    class UserGroupMembershipsController < ApplicationController
      before_action :load_team, except: :index
      before_action :load_user_group
      before_action :check_manage_permissions, except: %i(index show)

      def index; end

      def show; end

      def create
        ActiveRecord::Base.transaction do
          new_users = @team.users.where(id: params[:user_ids])

          new_users.each do |user|
            @user_group.user_group_memberships.create!(user: user, created_by: current_user)
          end

          render json: { message: :success }, status: :created
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error e.message
          head :unprocessable_entity
          raise ActiveRecord::Rollback
        end
      end

      def destroy; end

      private

      def load_team
        @team = Team.find(params[:team_id])
      end

      def load_user_group
        @user_group = @team.user_groups.find(params[:user_group_id])
      end

      def load_user_group_membership
        @user_group_membership = @user_group.user_group_memberships.find(params[:id])
      end

      def check_manage_permissions
        render_403 unless can_manage_team?(@team)
      end
    end
  end
end
