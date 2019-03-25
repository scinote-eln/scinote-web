# frozen_string_literal: true

class AddUniqueIndexOnUserTeams < ActiveRecord::Migration[5.1]
  def up
    # firstly delete the duplicates
    execute 'WITH uniq AS
      (SELECT DISTINCT ON (user_id, team_id) * FROM user_teams)
      DELETE FROM user_teams WHERE user_teams.id NOT IN
      (SELECT id FROM uniq)'
    add_index :user_teams, %i(user_id team_id), unique: true
  end

  def down
    remove_index :user_teams, column: %i(user_id team_id)
  end
end
