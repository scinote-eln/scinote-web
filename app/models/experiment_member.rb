# frozen_string_literal: true

class ExperimentMember
  include ActiveModel::Model

  attr_accessor :user_id, :user_role_id
  attr_reader :current_user, :experiment, :user, :project, :user_role


  def initialize(current_user, experiment, project, user = nil)
    @experiment = experiment
    @current_user = current_user
    @project = project

    if user
      @user = user
      @user_role = UserAssignment.find_by(assignable: experiment, user: user)&.user_role
    end
  end

  def update(params)
    self.user_role_id = params[:user_role_id]
    self.user_id = params[:user_id]

    ActiveRecord::Base.transaction do
      @user = @project.users.find(user_id)
      @user_role = UserRole.find_by(id: user_role_id)
      user_assignment = UserAssignment.find_by(assignable: experiment, user: user)

      if user_assignment.present? && user_role.nil?
        user_assignment.destroy
      elsif user_assignment.present?
        user_assignment.update!(user_role: user_role)
      else
        UserAssignment.create!(
          assignable: experiment,
          user: user,
          user_role: user_role,
          assigned_by: current_user
        )
      end
    end
  end
end
