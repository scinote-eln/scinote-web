# frozen_string_literal: true

class MigrateToNewUserRoles < ActiveRecord::Migration[6.1]
  def change
    reversible do |dir|
      dir.up do
        owner_role = UserRole.owner_role
        owner_role.save!
        normal_user_role = UserRole.normal_user_role
        normal_user_role.save!
        technician_role = UserRole.technician_role
        technician_role.save!
        viewer_role = UserRole.viewer_role
        viewer_role.save!

        create_user_assignments(UserProject.owner, owner_role)
        create_user_assignments(UserProject.normal_user, normal_user_role)
        create_user_assignments(UserProject.technician, technician_role)
        create_user_assignments(UserProject.viewer, viewer_role)
        create_public_project_assignments
      end
      dir.down do
        UserAssignment.joins(:user_role).where(user_role: { predefined: true }).delete_all
        Project.where(default_public_user_role: UserRole.where(predefined: true))
               .update_all(default_public_user_role_id: nil)
        UserRole.where(predefined: true).delete_all
      end
    end
  end

  private

  def new_user_assignment(user, assignable, user_role, assigned)
    UserAssignment.new(
      user: user,
      assignable: assignable,
      assigned: assigned,
      user_role: user_role
    )
  end

  def create_public_project_assignments
    viewer_role = UserRole.find_by(name: UserRole.viewer_role.name)

    Team.preload(:users).find_each do |team|
      public_projects = team.projects.where(visibility: 'visible')
      public_projects.preload(:team, experiments: :my_modules).find_each(batch_size: 10) do |project|
        project.update!(default_public_user_role: viewer_role)

        user_assignments = []
        already_assigned_user_ids = project.user_assignments.pluck(:user_id)
        unassigned_users = team.users.reject { |u| already_assigned_user_ids.include?(u.id) }

        unassigned_users.each do |user|
          user_assignments << new_user_assignment(user, project, viewer_role, :automatically)
          project.experiments.each do |experiment|
            user_assignments << new_user_assignment(user, experiment, viewer_role, :automatically)
            experiment.my_modules.each do |my_module|
              user_assignments << new_user_assignment(user, my_module, viewer_role, :automatically)
            end
          end
        end
        UserAssignment.import(user_assignments)
      end
    end
  end

  def create_user_assignments(user_projects, user_role)
    user_projects.includes(:user, :project).find_in_batches(batch_size: 100) do |user_project_batch|
      user_assignments = []
      user_project_batch.each do |user_project|
        user_assignments << new_user_assignment(user_project.user, user_project.project, user_role, :manually)
        user_project.project.experiments.preload(:my_modules).each do |experiment|
          user_assignments << new_user_assignment(user_project.user, experiment, user_role, :automatically)
          experiment.my_modules.each do |my_module|
            user_assignments << new_user_assignment(user_project.user, my_module, user_role, :automatically)
          end
        end
      end
      UserAssignment.import(user_assignments)
    end
  end
end
