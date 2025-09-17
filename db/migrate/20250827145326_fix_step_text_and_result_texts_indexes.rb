# frozen_string_literal: true

class FixStepTextAndResultTextsIndexes < ActiveRecord::Migration[7.2]
  include DatabaseHelper

  def up
    remove_index :step_texts, :name
    add_gin_index_without_tags :step_texts, :name

    remove_index :result_texts, :name
    add_gin_index_without_tags :result_texts, :name
  end

  def down
    remove_index :result_texts, name: 'index_result_texts_on_name'
    add_index :result_texts, :name

    remove_index :step_texts, name: 'index_step_texts_on_name'
    add_index :step_texts, :name
  end
end
