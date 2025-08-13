# frozen_string_literal: true

module Users
  module Settings
    class UserGroupsController < ApplicationController
      before_action :load_team
      before_action :set_breadcrumbs_items, only: %i(index show)
      before_action :check_user_groups_enabled, except: :users
      before_action :load_user_group, except: %i(index unassigned_users actions_toolbar create)
      before_action :check_read_permissions, only: %i(users)
      before_action :check_manage_permissions, except: %i(users)

      def index
        respond_to do |format|
          format.html do
            @active_tab = :user_groups
          end
          format.json do
            user_groups = Lists::UserGroupsService.new(@team.user_groups, params).call
            render json: user_groups, each_serializer: Lists::UserGroupSerializer, user: current_user, meta: pagination_dict(user_groups)
          end
        end
      end

      def actions_toolbar
        render json: {
          actions:
            Toolbars::UserGroupsService.new(
              current_user,
              @team,
              user_group_ids: JSON.parse(params[:items]).pluck('id')
            ).actions
        }
      end

      def unassigned_users
        @unassigned_users = @team.users.search(false, params[:query])
        if params[:user_group_id].present?
          @user_group = @team.user_groups.find(params[:user_group_id])
          @unassigned_users = @unassigned_users.where.not(id: @user_group.users.select(:id))
        end
      end

      def show
        @active_tab = :user_groups
      end

      def create
        @user_group = @team.user_groups.new
        @user_group.created_by = current_user
        @user_group.last_modified_by = current_user
        @user_group.assign_attributes(user_group_params)

        if @user_group.save
          log_activity(:create_user_group)
          @user_group.users.each do |user|
            log_activity(:add_group_user_member, { user_target: user.id })
          end
          render json: { message: t('user_groups.create.success') }, status: :created
        else
          render json: { error: @user_group.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def update
        ActiveRecord::Base.transaction do
          @user_group.last_modified_by = current_user
          @user_group.assign_attributes(user_group_params)
          @user_group.save!
          log_activity(:update_user_group)
          render json: {}, status: :ok
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: e.message }, status: :unprocessable_entity
          raise ActiveRecord::Rollback
        end
      end

      def destroy
        log_activity(:delete_user_group)
        if @user_group.destroy
          render json: { message: t('user_groups.delete.success') }, status: :ok
        else
          render json: { errors: t('user_groups.delete.error') }, status: :unprocessable_entity
        end
      end

      def users
        render json: @user_group.users, each_serializer: UserSerializer, user: current_user
      end

      private

      def check_user_groups_enabled
        @active_tab = :user_groups
        render '/users/settings/user_groups/promo' unless UserGroup.enabled?
      end

      def user_group_params
        params.require(:user_group).permit(
          :name,
          user_group_memberships_attributes: %i(id user_id)
        )
      end

      def load_team
        @team = Team.find(params[:team_id])
      end

      def load_user_group
        @user_group = @team.user_groups.find(params[:user_group_id] || params[:id])
      end

      def check_read_permissions
        render_403 unless can_read_team?(@team)
      end

      def check_manage_permissions
        render_403 unless can_manage_team?(@team)
      end

      def log_activity(type_of, message_items = {})
        Activities::CreateActivityService
          .call(activity_type: type_of,
                owner: current_user,
                subject: @user_group.team,
                team: @user_group.team,
                message_items: {
                  user_group: @user_group.id,
                  team: @user_group.team.id
                }.merge(message_items))
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
