# frozen_string_literal: true

module Users
  module Settings
    class UserGroupMembershipsController < ApplicationController
      before_action :check_user_groups_enabled
      before_action :load_team
      before_action :load_user_group
      before_action :check_manage_permissions, except: %i(index show)

      def index
        memberships = Lists::UserGroupMembershipsService.new(@user_group.user_group_memberships, params).call
        render json: memberships, each_serializer: Lists::UserGroupMembershipSerializer, user: current_user, meta: pagination_dict(memberships)
      end

      def actions_toolbar
        render json: {
          actions:
            Toolbars::UserGroupMembershipsService.new(
              current_user,
              @user_group,
              user_group_membership_ids: JSON.parse(params[:items]).pluck('id')
            ).actions
        }
      end

      def show; end

      def create
        ActiveRecord::Base.transaction do
          new_users = @team.users.where(id: params[:user_ids])

          new_users.each do |user|
            @user_group.user_group_memberships.create!(user: user, created_by: current_user)
            log_activity(:add_group_user_member, user)
          end

          render json: { message: :success }, status: :created
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error e.message
          head :unprocessable_entity
          raise ActiveRecord::Rollback
        end
      end

      def destroy_multiple
        members = @user_group.user_group_memberships.where(id: params[:membership_ids])

        members.each do |member|
          log_activity(:remove_group_user_member, member.user)
        end

        if members.destroy_all
          render json: { message: :success }, status: :ok
        else
          head :unprocessable_entity
        end
      end

      private

      def check_user_groups_enabled
        render '/users/settings/user_groups/promo' unless UserGroup.enabled?
      end

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

      def log_activity(type_of, user_target)
        Activities::CreateActivityService
          .call(activity_type: type_of,
                owner: current_user,
                subject: @user_group.team,
                team: @user_group.team,
                message_items: {
                  user_group: @user_group.id,
                  team: @user_group.team.id,
                  user_target: user_target.id
                })
      end
    end
  end
end
