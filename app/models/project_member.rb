# frozen_string_literal: true

class ProjectMember
  include ActiveModel::Model

  attr_accessor :user, :project, :assign, :user_role_id, :user_id
  attr_reader :current_user, :user_assignment, :user_role, :user_project

  delegate :user_role, to: :user_assignment, allow_nil: true

  validates :user, :project, presence: true, if: -> { assign }
  validates :user_role_id, presence: true, if: -> { assign }
  validate :validate_role_presence, if: -> { assign }

  def initialize(user, project, current_user = nil)
    @user = user
    @project = project
    @current_user = current_user
    @user_assignment = UserAssignment.find_by(assignable: @project, user: @user)
  end

  def save
    return unless assign

    ActiveRecord::Base.transaction do
      @user_assignment = UserAssignment.find_or_initialize_by(
        assignable: @project,
        user: @user
      )

      @user_assignment.update!(
        user_role_id: user_role_id,
        assigned_by: current_user,
        assigned: :manually
      )

      log_activity(:assign_user_to_project)

      UserAssignments::PropagateAssignmentJob.perform_later(
        @project,
        @user,
        user_role,
        current_user
      )
    end
  end

  def update
    validate_role_presence
    return false unless valid?

    ActiveRecord::Base.transaction do
      @user_assignment = UserAssignment.find_by!(assignable: @project, user: @user)
      @user_assignment.update!(user_role_id: user_role_id, assigned: :manually)
      log_activity(:change_user_role_on_project)

      UserAssignments::PropagateAssignmentJob.perform_later(
        @project,
        @user,
        user_role,
        current_user
      )
    end
  end

  def destroy
    user_assignment = UserAssignment.find_by!(assignable: @project, user: @user)
    user_project = UserProject.find_by(project: @project, user: @user)
    return false if last_project_owner?

    ActiveRecord::Base.transaction do
      # if project is public, the assignment
      # will reset to the default public role
      if @project.visible?
        user_assignment.update!(
          user_role: @project.default_public_user_role,
          assigned: :automatically
        )
      else
        user_assignment.destroy!
        user_project&.destroy!
      end

      UserAssignments::PropagateAssignmentJob.perform_later(
        @project,
        @user,
        user_role,
        current_user,
        destroy: true
      )

      log_activity(:unassign_user_from_project)
    end
  end

  def assign=(value)
    @assign = ActiveModel::Type::Boolean.new.cast(value)
  end

  def last_project_owner?
    project_owners.count == 1 && user_role.owner?
  end

  private

  def log_activity(type_of)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: project,
            team: project.team,
            project: project,
            message_items: { project: project.id,
                             user_target: user.id,
                             role: user_role.name })
  end

  def validate_role_presence
    errors.add(:user_role_id, :not_found) if UserRole.find_by(id: user_role_id).nil?
  end

  def project_owners
    @project_owners ||= @project.user_assignments
                                .includes(:user_role)
                                .where(user_roles: { name: I18n.t('user_roles.predefined.owner') })
  end
end
