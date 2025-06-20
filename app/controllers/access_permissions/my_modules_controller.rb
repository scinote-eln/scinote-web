# frozen_string_literal: true

module AccessPermissions
  class MyModulesController < ApplicationController
    before_action :set_my_module
    before_action :set_experiment
    before_action :set_project
    before_action :check_read_permissions, only: %i(show show_user_group_assignments)
    before_action :check_manage_permissions, only: %i(edit update)

    def show
      render json: @my_module.user_assignments.includes(:user_role, :user).order('users.full_name ASC'),
             each_serializer: UserAssignmentSerializer, user: current_user
    end

    def show_user_group_assignments
      render json: @my_module.user_group_assignments.includes(:user_role, :user_group).order('user_groups.name ASC'),
             each_serializer: UserGroupAssignmentSerializer, user: current_user
    end

    def new
      render json: @available_users, each_serializer: UserSerializer, user: current_user
    end
    def edit; end

    def update
      assignment_type = if permitted_update_params[:user_id].present?
                          'user'
                        elsif permitted_update_params[:user_group_id].present?
                          'user_group'
                        end
      assignment_key = "#{assignment_type}_id".to_sym

      id = permitted_update_params[assignment_key]
      @assignment = @my_module.public_send("#{assignment_type}_assignments").find_by(assignment_key => id, team: current_team)

      if permitted_update_params[:user_role_id] == 'reset'
        @assignment.update!(
          user_role_id: @experiment.public_send("#{assignment_type}_assignments").find_by(assignment_key => id, team: current_team).user_role_id,
          assigned: :automatically
        )
      else
        @assignment.update!(
          user_role_id: permitted_update_params[:user_role_id],
          assigned_by: current_user,
          assigned: :manually
        )
      end

      log_change_activity unless @assignment.respond_to?(:user_group)
    end

    private

    def permitted_update_params
      params.require(:user_assignment)
            .permit(%i(user_role_id user_id user_group_id))
    end

    def set_project
      @project = @experiment.project
    end

    def set_experiment
      @experiment = @my_module.experiment
    end

    def set_my_module
      @my_module = MyModule.includes(user_assignments: %i(user user_role)).find_by(id: params[:id])

      render_404 unless @my_module
    end

    def check_manage_permissions
      render_403 unless can_manage_my_module_users?(@my_module)
    end

    def check_read_permissions
      render_403 unless can_read_my_module?(@my_module)
    end

    def log_change_activity
      Activities::CreateActivityService.call(
        activity_type: :change_user_role_on_my_module,
        owner: current_user,
        subject: @my_module,
        team: @project.team,
        project: @project,
        message_items: {
          my_module: @my_module.id,
          user_target: @assignment.user_id,
          role: @assignment.user_role.name
        }
      )
    end
  end
end
