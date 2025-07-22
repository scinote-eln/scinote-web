# frozen_string_literal: true

class MoveEveryOneElseAssignmentToTeamAssignments < ActiveRecord::Migration[7.2]
  def up
    viewer_role = UserRole.find_predefined_viewer_role
    normal_user_role = UserRole.find_predefined_normal_user_role

    # Shared repositories with read permission
    TeamSharedObject.where(permission_level: Extends::SHARED_OBJECTS_PERMISSION_LEVELS[:shared_read])
                    .find_each do |shared_obj|
                      next if shared_obj.shared_repository.blank?

                      shared_obj.shared_repository.user_assignments.where(team_id: shared_obj.team_id).delete_all
                      shared_obj.shared_repository.team_assignments.find_or_create_by!(team_id: shared_obj.team_id, user_role: viewer_role)
                    end

    # Shared repositories with write permission
    TeamSharedObject.where(permission_level: Extends::SHARED_OBJECTS_PERMISSION_LEVELS[:shared_write])
                    .find_each do |shared_obj|
                      next if shared_obj.shared_repository.blank?

                      shared_obj.shared_repository.user_assignments.where(team_id: shared_obj.team_id, user_role: normal_user_role).delete_all
                      shared_obj.shared_repository.team_assignments.find_or_create_by!(team_id: shared_obj.team_id, user_role: normal_user_role)
                    end

    # Other repositories
    Repository.find_each do |repository|
      repository.user_assignments.where(team_id: repository.team_id).update_all(assigned: :manually)

      repository.user_assignments.where(team_id: repository.team_id, user_role: normal_user_role).delete_all
      repository.team_assignments.find_or_create_by!(team_id: repository.team_id, user_role: normal_user_role)
    end

    # global share
    Repository.where(permission_level: %i(shared_read shared_write)).find_each do |repository|
      Team.where.not(id: repository.team_id).find_each do |team|
        next if repository.private_shared_with?(team) || repository.team_assignments.exists?(team: team)

        repository.user_assignments.where(team: team).delete_all

        if repository.permission_level == 'shared_read'
          repository.team_assignments.find_or_create_by!(team_id: team.id, user_role: viewer_role)
        else
          repository.team_assignments.find_or_create_by!(team_id: team.id, user_role: normal_user_role)
          team.user_assignments.where.not(user_role: normal_user_role).find_each do |user_assignment|
            UserAssignment.create!(
              assignable: repository,
              team: team,
              user: user_assignment.user,
              user_role: user_assignment.user_role,
              assigned: :manually
            )
          end
        end
      end
    end

    # Forms
    Form.find_each do |form|
      replace_automatic_user_assignments_with_team_assignment(record: form, team_id: form.team_id)
    end

    # Protocols
    Protocol.where(protocol_type: %i(in_repository_published_original in_repository_draft in_repository_published_version))
            .find_each do |protocol|
              replace_automatic_user_assignments_with_team_assignment(record: protocol, team_id: protocol.team_id)
            end

    # PET
    Project.visible.preload(:experiments).find_in_batches(batch_size: 100) do |projects|
      projects.each do |project|
        project_automatic_user_assignments = project.user_assignments.where(assigned: :automatically)
        next if project_automatic_user_assignments.blank?

        user_role = project_automatic_user_assignments.first.user_role
        team_assignment_values = []

        project.experiments.preload(:my_modules).each do |experiment|
          experiment.my_modules.each do |my_module|
            team_assignment_values << new_team_assignment(project.team_id, my_module, user_role)
            my_module.automatic_user_assignments.where(user_id: project_automatic_user_assignments.select(:user_id)).delete_all
          end
          team_assignment_values << new_team_assignment(project.team_id, experiment, user_role)
          experiment.automatic_user_assignments.where(user_id: project_automatic_user_assignments.select(:user_id)).delete_all
        end

        team_assignment_values << new_team_assignment(project.team_id, project, user_role)
        project_automatic_user_assignments.delete_all

        TeamAssignment.import(team_assignment_values, validate: false)
      end
    end
  end

  def down
    team_shared_read_objects = TeamSharedObject.where(permission_level: Extends::SHARED_OBJECTS_PERMISSION_LEVELS[:shared_read])

    team_shared_read_objects.find_each do |team_shared_object|
      next if team_shared_object.shared_repository.blank?

      # shared repositories with read permission
      TeamAssignment.where(assignable: team_shared_object.shared_repository, team_id: team_shared_object.team_id).delete_all

      user_assignments = team_shared_object.team.user_assignments
      user_assignments.find_each do |user_assignment|
        UserAssignment.create!(assignable: team_shared_object.shared_repository,
                               team_id: team_shared_object.team_id,
                               user: user_assignment.user,
                               user_role: user_assignment.user_role)
      end
    end

    remove_team_assignments(TeamAssignment.where(assignable_type: 'RepositoryBase'))
    remove_team_assignments(TeamAssignment.where(assignable_type: 'Form'))
    remove_team_assignments(TeamAssignment.where(assignable_type: 'Protocol'))
    remove_team_assignments(TeamAssignment.where(assignable_type: 'MyModule'))
    remove_team_assignments(TeamAssignment.where(assignable_type: 'Experiment'))
    remove_team_assignments(TeamAssignment.where(assignable_type: 'Project'))
  end

  private

  def new_team_assignment(team_id, assignable, user_role)
    TeamAssignment.new(
      team_id: team_id,
      assignable: assignable,
      user_role: user_role
    )
  end

  def replace_automatic_user_assignments_with_team_assignment(record:, team_id:)
    scope = record.user_assignments.where(team_id: team_id, assigned: :automatically)

    return if scope.blank?

    record.team_assignments.create!(team_id: team_id, user_role: scope.first.user_role)
    scope.delete_all
  end

  def new_user_assignment(user, assignable, user_role, assigned, team)
    UserAssignment.new(
      user: user,
      assignable: assignable,
      assigned: assigned,
      user_role: user_role,
      team: team
    )
  end

  def remove_team_assignments(data)
    user_assignment_values = []
    ids_to_destroy = []

    data.find_each do |obj|
      user_assignments = obj.team.user_assignments.includes(:user).where.not(user_id: obj.assignable.user_assignments.select(:user_id))
      user_assignments.find_each do |user_assignment|
        user_assignment_values << new_user_assignment(user_assignment.user, obj.assignable, obj.user_role, :automatically, obj.team)
      end

      ids_to_destroy << obj.id
    end

    TeamAssignment.where(id: ids_to_destroy).delete_all
    UserAssignment.import(user_assignment_values, validate: false)
  end
end
