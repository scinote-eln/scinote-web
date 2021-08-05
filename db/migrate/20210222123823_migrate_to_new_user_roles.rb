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

        UserProject.delete_all
      end
      dir.down do
        project_assignments = UserAssignment.joins(:user_role).where(assignable_type: 'Project')
        create_user_project(
          project_assignments.where(user_role: { name: I18n.t('user_roles.predefined.owner'), predefined: true }),
          'owner'
        )
        create_user_project(
          project_assignments.where(user_role: { name: I18n.t('user_roles.predefined.normal_user'), predefined: true }),
          'normal_user'
        )
        create_user_project(
          project_assignments.where(user_role: { name: I18n.t('user_roles.predefined.technician'), predefined: true }),
          'technician'
        )
        create_user_project(
          project_assignments.where(user_role: { name: I18n.t('user_roles.predefined.viewer'), predefined: true }),
          'viewer'
        )

        UserAssignment.joins(:user_role).where(user_role: { predefined: true }).delete_all
        UserRole.where(predefined: true).delete_all
      end
    end
  end

  private

  def create_user_assignments(user_projects, user_role)
    user_projects.includes(:user, :project).find_in_batches(batch_size: 100) do |user_project_batch|
      user_assignments = []
      user_project_batch.each do |user_project|
        user_assignments << UserAssignment.new(user: user_project.user,
                                               assignable: user_project.project,
                                               user_role: user_role)
        user_project.project.experiments.each do |experiment|
          user_assignments << UserAssignment.new(user: user_project.user,
                                               assignable: experiment,
                                               user_role: user_role)
          experiment.my_modules.each do |my_module|
            user_assignments << UserAssignment.new(user: user_project.user,
                                               assignable: my_module,
                                               user_role: user_role)
          end
        end
      end
      UserAssignment.import(user_assignments)
    end
  end

  def create_user_project(user_roles, role)
    user_roles.includes(:user, :assignable).find_in_batches(batch_size: 100) do |user_role_batch|
      user_projects = []
      user_role_batch.each do |user_role|
        user_projects << UserProject.new(user: user_role.user, project: user_role.assignable, role: role)
      end
      UserProject.import(user_projects)
    end
  end
end
