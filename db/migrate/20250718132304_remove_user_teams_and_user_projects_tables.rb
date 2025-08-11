# frozen_string_literal: true

class RemoveUserTeamsAndUserProjectsTables < ActiveRecord::Migration[7.2]
  def up
    drop_table :user_projects, if_exists: true
    drop_table :user_teams, if_exists: true
  end
end
