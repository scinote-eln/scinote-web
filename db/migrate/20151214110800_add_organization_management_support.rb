require File.expand_path('app/helpers/database_helper')
include DatabaseHelper

class AddOrganizationManagementSupport < ActiveRecord::Migration
  def up
    # Add nullable description to organization
    add_column :organizations, :description, :string

    # Add estimated file size to asset (in B)
    add_column :assets, :estimated_size, :integer,
      default: 0
    change_column_null :assets, :estimated_size, false

    # Add space taken to organization (in B!)
    add_column :organizations, :space_taken, :integer,
      limit: 5, default: MINIMAL_ORGANIZATION_SPACE_TAKEN
    change_column_null :organizations, :space_taken, false

    # Add reference to private user
    add_column :organizations, :private_user_id, :integer
    add_index :organizations, :private_user_id
    add_foreign_key :organizations, :users, column: :private_user_id
  end

  def down
    remove_column :organizations, :description

    remove_column :assets, :estimated_size

    remove_column :organizations, :space_taken

    remove_foreign_key :organizations, column: :private_user_id
    remove_index :organizations, :private_user_id
    remove_column :organizations, :private_user_id
  end
end
