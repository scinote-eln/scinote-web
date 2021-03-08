# frozen_string_literal: true

class AddUnseenByToComments < ActiveRecord::Migration[6.0]
  def change
    add_column :comments, :unseen_by, :bigint, array: true, default: []
  end
end
