# frozen_string_literal: true

class MyModuleMember
  include ActiveModel::Model

  attr_accessor :user_id, :user_role_id
  attr_reader :current_user, :my_module,
              :experiment, :user, :project,
              :user_role, :user_assignment

  def initialize(current_user, my_module, experiment, project, user = nil, user_assignment = nil)
    @experiment = experiment
    @current_user = current_user
    @project = project
    @my_module = my_module
    @user_assignment = user_assignment

    if user
      @user = user
      @user_role = UserAssignment.find_by(assignable: my_module, user: user)&.user_role
    end
  end

  def update(params)
    initialize_user_assignment!(params)

    ActiveRecord::Base.transaction do
      user_assignment.update!(user_role: user_role, assigned: :manually)
      log_change_activity
    end
  end

  def reset(params)
    initialize_user_assignment!(params)

    ActiveRecord::Base.transaction do
      @user_role =
        @my_module.experiment
                  .user_assignments
                  .find_by(user: user_assignment.user)
                  .user_role

      user_assignment.update!(user_role: @user_role, assigned: :automatically)
      log_change_activity
    end
  end

  private

  def initialize_user_assignment!(params)
    self.user_role_id = params[:user_role_id]
    self.user_id = params[:user_id]

    @user = @project.users.find(user_id)
    @user_role = UserRole.find_by(id: user_role_id)
    @user_assignment = UserAssignment.find_by(assignable: my_module, user: user)
  end

  def log_change_activity
    Activities::CreateActivityService.call(
      activity_type: :change_user_role_on_my_module,
      owner: current_user,
      subject: my_module,
      team: project.team,
      project: project,
      message_items: {
        my_module: my_module.id,
        user_target: user.id,
        role: user_role.name
      }
    )
  end
end
