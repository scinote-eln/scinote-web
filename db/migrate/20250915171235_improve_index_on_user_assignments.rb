# frozen_string_literal: true

class ImproveIndexOnUserAssignments < ActiveRecord::Migration[7.2]
  def change
    add_index :user_assignments,
              %i(assignable_type team_id user_id user_role_id),
              name: 'index_user_assignments_assignable_type_team_user_user_role'
  end
end
