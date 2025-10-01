# frozen_string_literal: true

class CreateResultTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :result_templates do |t|
      t.string :name
      t.bigint :protocol_id
      t.bigint :user_id
      t.bigint :last_modified_by_id
      t.integer :assets_view_mode, default: 0
      t.datetime :discarded_at

      t.timestamps
    end

    add_reference :result_orderable_elements, :result_template, foreign_key: true, null: true
    add_reference :result_tables, :result_template, foreign_key: true, null: true
    add_reference :result_texts, :result_template, foreign_key: true, null: true
    add_reference :result_assets, :result_template, foreign_key: true, null: true

    change_column_null :result_orderable_elements, :result_id, true
    change_column_null :result_tables, :result_id, true
    change_column_null :result_texts, :result_id, true
    change_column_null :result_assets, :result_id, true
  end
end
