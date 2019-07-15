# frozen_string_literal: true

class AddUniqueIndexToTeamRepositories < ActiveRecord::Migration[5.2]
  def change
    add_index :team_repositories, %i(team_id repository_id), unique: true
  end
end
