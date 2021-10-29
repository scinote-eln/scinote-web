# frozen_string_literal: true

class ExperimentMember
  include ActiveModel::Model

  attr_accessor :user_id, :user_role_id
  attr_reader :current_user, :experiment,
              :user, :project, :user_role,
              :user_assignment

  def initialize(current_user, experiment, project, user = nil, user_assignment = nil)
    @experiment = experiment
    @current_user = current_user
    @project = project
    @user_assignment = user_assignment

    if user
      @user = user
      @user_role = UserAssignment.find_by(assignable: experiment, user: user)&.user_role
    end
  end

  def update(params)
    initialize_user_assignment!(params)

    ActiveRecord::Base.transaction do
      user_assignment.update!(user_role: user_role, assigned: :manually)
      log_activity(:change_user_role_on_experiment)
    end
  end

  def destroy
    @user_assignment = UserAssignment.find_by!(user: user, assignable: experiment)

    ActiveRecord::Base.transaction do
      @user_assignment.destroy!
      log_activity(:unassign_user_from_experiment)

      UserAssignments::PropagateAssignmentJob.perform_later(
        @experiment,
        @user,
        user_role,
        current_user,
        destroy: true
      )
    end
  end

  private

  def initialize_user_assignment!(params)
    self.user_role_id = params[:user_role_id]
    self.user_id = params[:user_id]

    @user = @experiment.users.find(user_id)
    @user_role = UserRole.find_by(id: user_role_id)
    @user_assignment ||= UserAssignment.find_by(assignable: experiment, user: user)
  end

  def log_activity(type_of)
    Activities::CreateActivityService
      .call(
        activity_type: type_of,
        owner: current_user,
        subject: experiment,
        team: project.team,
        project: project,
        message_items: {
          experiment: experiment.id,
          user_target: user.id,
          role: user_role.name
        }
      )
  end
end
