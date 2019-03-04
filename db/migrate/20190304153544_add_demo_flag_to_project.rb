# frozen_string_literal: true
class AddDemoFlagToProject < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :demo, :boolean, null: false, default: false
  end
end
