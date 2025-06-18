# frozen_string_literal: true

class AddUserGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :user_groups do |t|
      t.string :name
      t.references :team, foreign_key: true, null: false
      t.references :created_by, foreign_key: { to_table: :users }, null: false
      t.references :last_modified_by, foreign_key: { to_table: :users }, null: false

      t.index 'LOWER(name), team_id', unique: true, name: 'index_user_groups_on_lower_name_and_team_id'

      t.timestamps
    end

    create_table :user_group_memberships do |t|
      t.references :user_group, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false
      t.references :created_by, foreign_key: { to_table: :users }

      t.index %i(user_group_id user_id), unique: true

      t.timestamps
    end

    create_table :user_group_assignments do |t|
      t.references :team, foreign_key: true, null: false
      t.references :assignable, polymorphic: true, null: false
      t.references :user_group, foreign_key: true, null: false
      t.references :user_role, foreign_key: true, null: false
      t.references :assigned_by, foreign_key: { to_table: :users }
      t.integer :assigned, null: false, default: 0

      t.index %i(user_group_id assignable_type assignable_id team_id), unique: true, name: 'index_user_group_assignments_on_unique_assignable_in_team'

      t.timestamps
    end

    create_table :team_assignments do |t|
      t.references :team, foreign_key: true, null: false
      t.references :assignable, polymorphic: true, null: false
      t.references :user_role, foreign_key: true, null: false
      t.references :assigned_by, foreign_key: { to_table: :users }
      t.integer :assigned, null: false, default: 0

      t.index %i(assignable_type assignable_id team_id), unique: true, name: 'index_team_assignments_on_unique_assignable_in_team'

      t.timestamps
    end
  end
end
