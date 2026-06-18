# frozen_string_literal: true

class AddProtocolLocks < ActiveRecord::Migration[7.2]
  def change
    %i(steps assets checklists tables form_responses step_texts result_texts).each do |table|
      add_column table, :locked, :boolean, default: false, null: false
      add_index table, :locked
    end

    add_column :protocols, :description_locked, :boolean, default: false, null: false
    add_index :protocols, :description_locked
  end
end
