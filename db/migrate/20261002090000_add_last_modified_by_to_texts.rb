# frozen_string_literal: true

class AddLastModifiedByToTexts < ActiveRecord::Migration[7.2]
  def change
    add_reference :step_texts, :last_modified_by, foreign_key: { to_table: :users }, index: true
    add_reference :result_texts, :last_modified_by, foreign_key: { to_table: :users }, index: true
  end
end
