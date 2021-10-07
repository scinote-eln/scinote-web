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
        UserRole.where(predefined: true).delete_all
      end
    end
  end

  private

  def new_user_assignment(user, assignable, user_role, assigned = :manually, existing_assignments = {})
    return if existing_assignments[[user.id, assignable.id, assignable.class.name]]

    UserAssignment.new(
      user: user,
      assignable: assignable,
      assigned: assigned,
      user_role: user_role
    )
  end

  def create_public_project_assignments
    user_assignments = []
    viewer_role = UserRole.find_by(name: I18n.t('user_roles.predefined.viewer'))
    public_projects = Project.where(visibility: 'visible')
    public_experiments = Experiment.where(project_id: public_projects.select(:id))
    public_my_modules = MyModule.where(experiment_id: public_experiments.select(:id))

    existing_user_assignments = UserAssignment.where(
      assignable_id: public_projects.select(:id),
      assignable_type: 'Project'
    ).or(
      UserAssignment.where(
        assignable_id: public_experiments.select(:id),
        assignable_type: 'Experiment'
      )
    ).or(
      UserAssignment.where(
        assignable_id: public_my_modules.select(:id),
        assignable_type: 'MyModule'
      )
    ).map { |ua| [[ua.user_id, ua.assignable_id, ua.assignable_type], true] }.to_h

    public_projects.find_each do |project|
      project.team.users.find_each do |user|
        user_assignments << new_user_assignment(
          user, project, viewer_role, :automatically, existing_user_assignments
        )
        project.experiments.find_each do |experiment|
          user_assignments << new_user_assignment(
            user, experiment, viewer_role, :automatically, existing_user_assignments
          )
          experiment.my_modules.find_each do |my_module|
            user_assignments << new_user_assignment(
              user, my_module, viewer_role, :automatically, existing_user_assignments
            )
          end
        end
      end
    end

    UserAssignment.import(user_assignments.compact)
  end

  def create_user_assignments(user_projects, user_role)
    user_projects.includes(:user, :project).find_in_batches(batch_size: 100) do |user_project_batch|
      user_assignments = []
      user_project_batch.each do |user_project|
        user_assignments << new_user_assignment(user_project.user, user_project.project, user_role)
        user_project.project.experiments.each do |experiment|
          user_assignments << new_user_assignment(user_project.user, experiment, user_role)
          experiment.my_modules.each do |my_module|
            user_assignments << new_user_assignment(user_project.user, my_module, user_role)
          end
        end
      end
      UserAssignment.import(user_assignments.compact)
    end
  end
end
