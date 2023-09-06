# frozen_string_literal: true

require File.expand_path('app/helpers/database_helper')

class AddNameColumnToTextComponent < ActiveRecord::Migration[7.0]
  include DatabaseHelper

  def up
    add_column :result_texts, :name, :string
    add_column :step_texts, :name, :string
    add_gist_index :result_texts, :name
    add_gist_index :step_texts, :name
  end

  def down
    remove_index :step_texts, :name
    remove_index :result_texts, :name
    remove_column :step_texts, :name
    remove_column :result_texts, :name
  end
end
