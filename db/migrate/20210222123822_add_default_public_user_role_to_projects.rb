# frozen_string_literal: true

class AddDefaultPublicUserRoleToProjects < ActiveRecord::Migration[6.1]
  def change
    add_reference :projects, :default_public_user_role, foreign_key: { to_table: :user_roles }
  end
end
