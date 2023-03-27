# frozen_string_literal: true
class AddIndexToRepositories < ActiveRecord::Migration[6.1]
  def change
    add_index :repositories, :archived
  end
end
