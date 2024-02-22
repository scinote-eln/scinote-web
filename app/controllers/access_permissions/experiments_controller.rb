# frozen_string_literal: true

module AccessPermissions
  class ExperimentsController < ApplicationController
    before_action :set_experiment
    before_action :set_project
    before_action :check_read_permissions, only: %i(show)
    before_action :check_manage_permissions, only: %i(edit update)

    def show
      render json: @experiment.user_assignments.includes(:user_role, :user).order('users.full_name ASC'),
             each_serializer: UserAssignmentSerializer, user: current_user
    end

    def new
      render json: @available_users, each_serializer: UserSerializer, user: current_user
    end


    def edit; end

    def update
      user_id = permitted_update_params[:user_id]
      @user_assignment = @experiment.user_assignments.find_by(user_id: user_id, team: current_team)

      if permitted_update_params[:user_role_id] == 'reset'
        @user_assignment.update!(
          user_role_id: @project.user_assignments.find_by(user_id: user_id, team: current_team).user_role_id,
          assigned: :automatically
        )
      else
        @user_assignment.update!(
          user_role_id: permitted_update_params[:user_role_id],
          assigned: :manually
        )
      end

      UserAssignments::PropagateAssignmentJob.perform_later(
        @experiment,
        @user_assignment.user.id,
        @user_assignment.user_role,
        current_user.id
      )

      log_change_activity

      render json: {}, status: :ok
    end

    private

    def permitted_update_params
      params.require(:user_assignment)
            .permit(%i(user_role_id user_id))
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
          user_target: @user_assignment.user_id,
          role: @user_assignment.user_role.name
        }
      )
    end
  end
end
