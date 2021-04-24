# frozen_string_literal: true

class ProjectMember
  include ActiveModel::Model

  attr_accessor :user, :project, :assign, :user_role_id, :user_id
  attr_reader :current_user

  validates :user, :project, :user_role_id, presence: true
  validate :role_presence
  validate :validate_user_project_relation_presence
  validate :validate_user_project_assignment_presence

  def initialize(user, project, current_user)
    @user = user
    @project = project
    @current_user = current_user
  end

  def save
    return unless assign

    ActiveRecord::Base.transaction do
      UserProject.create!(project: @project, user: @user)
      UserAssignment.create!(assignable: @project, user: @user, user_role: set_user_role, assigned_by: current_user)
    end
  end

  def assign=(value)
    @assign = ActiveModel::Type::Boolean.new.cast(value)
  end

  private

  def set_user_role
    UserRole.find!(user_role_id)
  end

  def role_presence
    errors.add(:user_role_id) if UserRole.find(user_role_id).nil?
  end

  def validate_user_project_relation_presence
    if UserProject.find_by(project: @project, user: @user).present?
      errors.add(:user)
    end
  end

  def validate_user_project_assignment_presence
    if UserAssignment.find_by(assignable: @project, user: @user).present?
      errors.add(:user_role_id)
    end
  end
end
