# frozen_string_literal: true

class CreateUserRolesAndAssignments < ActiveRecord::Migration[6.1]
  def change
    create_table :user_roles do |t|
      t.string :name
      t.boolean :predefined, default: false
      t.string :permissions, array: true, default: []
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      t.references :last_modified_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    create_table :user_assignments do |t|
      t.references :assignable, polymorphic: true, null: false
      t.references :user, foreign_key: true, null: false
      t.references :user_role, foreign_key: true, null: false
      t.references :assigned_by, foreign_key: { to_table: :users }, null: true
      t.integer :assigned, null: false, default: 0

      t.timestamps
    end
  end
end
