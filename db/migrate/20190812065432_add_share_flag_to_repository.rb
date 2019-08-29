# frozen_string_literal: true

class AddShareFlagToRepository < ActiveRecord::Migration[5.2]
  def change
    add_column :repositories, :permission_level, :integer, null: false, default: 0
  end
end
