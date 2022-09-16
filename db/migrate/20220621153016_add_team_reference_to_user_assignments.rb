# frozen_string_literal: true

class AddTeamReferenceToUserAssignments < ActiveRecord::Migration[6.1]
  def up
    add_reference :user_assignments, :team, index: true, foreign_key: true
    UserAssignment.reset_column_information

    UserAssignment.preload(:assignable).find_each do |user_assignment|
      team = user_assignment.assignable.is_a?(Team) ? user_assignment.assignable : user_assignment.assignable.team
      user_assignment.update_column(:team_id, team.id)
    end
  end

  def down
    remove_reference :user_assignments, :team, index: true, foreign_key: true
  end
end
