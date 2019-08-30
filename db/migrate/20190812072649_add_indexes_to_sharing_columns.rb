# frozen_string_literal: true

class AddIndexesToSharingColumns < ActiveRecord::Migration[5.2]
  def change
    add_index :team_repositories, :permission_level
    add_index :repositories, :permission_level
    change_column_default :team_repositories, :permission_level, from: nil, to: 0
  end
end
