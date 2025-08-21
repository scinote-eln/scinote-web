# frozen_string_literal: true

class AddUniqueConstraintToUserAssignments < ActiveRecord::Migration[7.2]
  def up
    # delete the duplicates
    execute(
      'WITH uniq AS
      (SELECT DISTINCT ON (user_id, assignable_type, assignable_id, team_id) * FROM user_assignments)
      DELETE FROM user_assignments WHERE user_assignments.id NOT IN
        (SELECT id FROM uniq)'
    )

    remove_index :user_assignments, name: 'index_user_assignments_on_assignable'
    add_index :user_assignments,
              %i(assignable_type assignable_id user_id team_id),
              unique: true,
              name: 'index_user_assignments_on_unique_assignable_in_team'
  end

  def down
    add_index :user_assignments, %i(assignable_type assignable_id), name: 'index_user_assignments_on_assignable'
    remove_index :user_assignments, name: 'index_user_assignments_on_unique_assignable_in_team'
  end
end
