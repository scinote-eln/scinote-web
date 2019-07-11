# frozen_string_literal: true

class CreateTeamRepositories < ActiveRecord::Migration[5.2]
  def change
    create_table :team_repositories do |t|
      t.references :team, foreign_key: true
      t.references :repository, foreign_key: true
      t.integer :permission_level, null: false

      t.timestamps
    end
  end
end
