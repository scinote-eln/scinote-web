class AddCurrentOrganizationToUser < ActiveRecord::Migration[4.2]
  class TempUser < ApplicationRecord
    self.table_name = 'users'

    has_many :user_teams, inverse_of: :user
    has_many :teams, through: :user_teams
  end

  def up
    add_column :users, :current_team_id, :integer
    add_foreign_key :users, :teams, column: :current_team_id

    TempUser.find_each do |user|
      if user.teams.count > 0
        user.update(current_team_id: user.teams.first.id)
      end
    end
  end

  def down
    remove_column :users, :current_team_id
  end
end
