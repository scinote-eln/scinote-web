# frozen_string_literal: true

module Users
  module Settings
    class UserGroupsController < ApplicationController
      before_action :load_team
      before_action :load_user_group, except: %i(index unassigned_users actions_toolbar create)
      before_action :check_manage_permissions, except: %i(index show unassigned_users actions_toolbar)
      before_action :set_breadcrumbs_items, only: %i(index show)

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

      def show; end

      def create
        @user_group = @team.user_groups.new
        @user_group.created_by = current_user
        @user_group.last_modified_by = current_user
        @user_group.assign_attributes(user_group_params)

        if @user_group.save
          render json: { message: t('user_groups.create.success') }, status: :created
        else
          render json: { errors: t('user_groups.create.error') }, status: :unprocessable_entity
        end
      end

      def update; end

      def destroy
        if @user_group.destroy
          render json: { message: t('user_groups.delete.success') }, status: :ok
        else
          render json: { errors: t('user_groups.delete.error') }, status: :unprocessable_entity
        end
      end

      private

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
        @user_group = @team.user_groups.find(params[:id])
      end

      def check_manage_permissions
        render_403 unless can_manage_team?(@team)
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
