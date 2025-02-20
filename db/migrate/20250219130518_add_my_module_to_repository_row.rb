# frozen_string_literal: true

class AddMyModuleToRepositoryRow < ActiveRecord::Migration[7.0]
  def change
    add_reference :repository_rows, :my_module, null: true, foreign_key: true
  end
end
