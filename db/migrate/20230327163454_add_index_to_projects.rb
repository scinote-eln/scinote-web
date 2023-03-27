# frozen_string_literal: true
class AddIndexToProjects < ActiveRecord::Migration[6.1]
  def change
    add_index :projects, :archived
  end
end
