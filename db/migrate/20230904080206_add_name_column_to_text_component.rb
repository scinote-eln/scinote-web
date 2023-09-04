# frozen_string_literal: true

class AddNameColumnToTextComponent < ActiveRecord::Migration[7.0]
  def change
    add_column :result_texts, :name, :string, default: '', index: true
    add_column :step_texts, :name, :string, default: '', index: true
  end
end
