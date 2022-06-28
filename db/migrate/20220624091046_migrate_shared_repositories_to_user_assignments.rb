# frozen_string_literal: true

class MigrateSharedRepositoriesToUserAssignments < ActiveRecord::Migration[6.1]
  def up
    viewer_role = UserRole.find_by(name: UserRole.public_send('viewer_role').name)
    normal_user_role = UserRole.find_by(name: UserRole.public_send('normal_user_role').name)

    TeamRepository.where(permission_level: %i(shared_read shared_write))
                  .preload(:team, :repository)
                  .find_each do |team_repository|
      user_role = if team_repository.shared_read?
                    viewer_role
                  elsif team_repository.shared_write?
                    normal_user_role
                  end

      team_repository.team.users.find_in_batches(batch_size: 100) do |users_batch|
        user_assignments = []
        users_batch.each do |user|
          user_assignments << UserAssignment.new(user: user, assignable: team_repository.repository,
                                                 user_role: user_role, team: team_repository.team)
        end
        UserAssignment.import(user_assignments)
      end
    end
  end

  def down
    UserAssignment.joins("INNER JOIN repositories ON user_assignments.assignable_id = repositories.id "\
                         "AND user_assignments.assignable_type = 'RepositoryBase' "\
                         "AND user_assignments.team_id != repositories.team_id")
                  .delete_all
  end
end
