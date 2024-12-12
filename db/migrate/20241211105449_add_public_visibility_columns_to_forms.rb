# frozen_string_literal: true

class AddPublicVisibilityColumnsToForms < ActiveRecord::Migration[7.0]
  def change
    add_column :forms, :visibility, :integer, default: 0
    add_index :forms, :visibility

    add_reference :forms, :default_public_user_role, foreign_key: { to_table: :user_roles }
  end
end
