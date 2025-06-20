# frozen_string_literal: true

module AccessPermissions
  class ExperimentsController < ApplicationController
    before_action :set_experiment
    before_action :set_project
    before_action :check_read_permissions, only: %i(show show_user_group_assignments)
    before_action :check_manage_permissions, only: %i(edit update)

    def show
      render json: @experiment.user_assignments.includes(:user_role, :user).order('users.full_name ASC'),
             each_serializer: UserAssignmentSerializer, user: current_user
    end

    def show_user_group_assignments
      render json: @experiment.user_group_assignments.includes(:user_role, :user_group).order('user_groups.name ASC'),
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
      @assignment = @experiment.public_send("#{assignment_type}_assignments").find_by(assignment_key => id, team: current_team)

      if permitted_update_params[:user_role_id] == 'reset'
        @assignment.update!(
          user_role_id: @project.public_send("#{assignment_type}_assignments").find_by(assignment_key => id, team: current_team).user_role_id,
          assigned: :automatically
        )
      else
        @assignment.update!(
          user_role_id: permitted_update_params[:user_role_id],
          assigned_by: current_user,
          assigned: :manually
        )
      end

      is_group = @assignment.respond_to?(:user_group)

      UserAssignments::PropagateAssignmentJob.perform_later(
        @experiment,
        is_group ? @assignment.user_group.id : @assignment.user.id,
        @assignment.user_role,
        current_user.id,
        team_id: current_team.id,
        group: is_group
      )

      log_change_activity unless is_group

      render json: {}, status: :ok
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
      @experiment = Experiment.includes(user_assignments: %i(user user_role)).find_by(id: params[:id])

      render_404 unless @experiment
    end

    def check_manage_permissions
      render_403 unless can_manage_experiment_users?(@experiment)
    end

    def check_read_permissions
      render_403 unless can_read_experiment?(@experiment)
    end

    def log_change_activity
      Activities::CreateActivityService.call(
        activity_type: :change_user_role_on_experiment,
        owner: current_user,
        subject: @experiment,
        team: @project.team,
        project: @project,
        message_items: {
          experiment: @experiment.id,
          user_target: @assignment.user_id,
          role: @assignment.user_role.name
        }
      )
    end
  end
end
