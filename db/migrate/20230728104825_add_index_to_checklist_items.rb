# frozen_string_literal: true

class
 AddIndexToChecklistItems < ActiveRecord::Migration[7.0]
  def change
    add_index :checklist_items, %i(checklist_id position), unique: true
  end
end
