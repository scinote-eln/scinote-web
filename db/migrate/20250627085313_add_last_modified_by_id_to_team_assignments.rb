# frozen_string_literal: true

class AddLastModifiedByIdToTeamAssignments < ActiveRecord::Migration[7.2]
  def change
    add_reference :team_assignments, :last_modified_by, foreign_key: { to_table: :users }
  end
end
