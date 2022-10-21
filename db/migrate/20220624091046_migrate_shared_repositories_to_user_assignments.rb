# frozen_string_literal: true

class MigrateSharedRepositoriesToUserAssignments < ActiveRecord::Migration[6.1]
  class TeamRepository < ApplicationRecord
    self.table_name = 'team_repositories'
    enum permission_level: { not_shared: 0, shared_read: 1, shared_write: 2 }
    belongs_to :team
    belongs_to :repository
  end

  def up
    TeamRepository.where(permission_level: %i(shared_read shared_write))
                  .preload(:team, :repository)
                  .find_each do |team_repository|
      next if team_repository.repository.blank?

      team_repository.team
                     .user_assignments
                     .preload(:user, :user_role)
                     .find_each do |user_assignment|
        UserAssignment.create!(user: user_assignment.user, assignable: team_repository.repository,
                               user_role: user_assignment.user_role, team: team_repository.team)
      end
    end

    Repository.globally_shared.find_each do |repository|
      Team.where.not(id: repository.team.id).find_each do |team|
        team.user_assignments
            .preload(:user, :user_role)
            .find_each do |user_assignment|
          UserAssignment.create!(user: user_assignment.user, assignable: repository,
                                 user_role: user_assignment.user_role, team: team)
        end
      end
    end

    remove_index :repositories, :permission_level
    remove_index :team_repositories, :permission_level
    remove_index :team_repositories, :repository_id
    remove_index :team_repositories, %i(team_id repository_id), unique: true
    rename_table :team_repositories, :team_shared_objects
    rename_column :team_shared_objects, :repository_id, :shared_object_id
    add_column :team_shared_objects, :shared_object_type, :string
    execute("UPDATE team_shared_objects SET shared_object_type = 'RepositoryBase'")
    add_index :team_shared_objects,
              %i(shared_object_type shared_object_id team_id),
              name: 'index_team_shared_objects_on_shared_type_and_id_and_team_id',
              unique: true
  end

  def down
    remove_index :team_shared_objects,
                 %i(shared_object_type shared_object_id team_id),
                 name: 'index_team_shared_objects_on_shared_type_and_id_and_team_id',
                 unique: true
    remove_column :team_shared_objects, :shared_object_type
    rename_column :team_shared_objects, :shared_object_id, :repository_id
    rename_table :team_shared_objects, :team_repositories
    add_index :team_repositories, %i(team_id repository_id), unique: true
    add_index :team_repositories, :repository_id
    add_index :team_repositories, :permission_level
    add_index :repositories, :permission_level

    UserAssignment.joins("INNER JOIN repositories ON user_assignments.assignable_id = repositories.id "\
                         "AND user_assignments.assignable_type = 'RepositoryBase' "\
                         "AND user_assignments.team_id != repositories.team_id")
                  .delete_all
  end
end
