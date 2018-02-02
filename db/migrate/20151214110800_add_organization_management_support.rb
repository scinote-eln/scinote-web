require File.expand_path('app/helpers/database_helper')
include DatabaseHelper

class AddOrganizationManagementSupport < ActiveRecord::Migration[4.2]
  def up
    # Add nullable description to team
    add_column :teams, :description, :string

    # Add estimated file size to asset (in B)
    add_column :assets, :estimated_size, :integer,
      default: 0
    change_column_null :assets, :estimated_size, false

    # Add space taken to team (in B!)
    add_column :teams, :space_taken, :integer, limit: 5,
               default: Constants::MINIMAL_TEAM_SPACE_TAKEN
    change_column_null :teams, :space_taken, false

    # Add reference to private user
    add_column :teams, :private_user_id, :integer
    add_index :teams, :private_user_id
    add_foreign_key :teams, :users, column: :private_user_id
  end

  def down
    remove_column :teams, :description

    remove_column :assets, :estimated_size

    remove_column :teams, :space_taken

    remove_foreign_key :teams, column: :private_user_id
    remove_index :teams, :private_user_id
    remove_column :teams, :private_user_id
  end
end
