# frozen_string_literal: true

class RemoveForeignKeyConstraintFromTeamSharedObjects < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :team_shared_objects, :repositories, column: :shared_object_id
  end
end
