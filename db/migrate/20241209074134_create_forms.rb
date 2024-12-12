# frozen_string_literal: true

class CreateForms < ActiveRecord::Migration[7.0]
  def change
    create_table :forms do |t|
      t.string :name
      t.string :description
      t.references :team, index: true, foreign_key: { to_table: :teams }
      t.references :created_by, index: true, foreign_key: { to_table: :users }
      t.references :last_modified_by, index: true, foreign_key: { to_table: :users }
      t.references :parent, index: true, foreign_key: { to_table: :forms }
      t.references :published_by, index: true, foreign_key: { to_table: :users }
      t.datetime :published_on
      t.boolean :archived, default: false, null: false
      t.datetime :archived_on
      t.datetime :restored_on
      t.references :archived_by, index: true, foreign_key: { to_table: :users }
      t.references :restored_by, index: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    create_table :form_fields do |t|
      t.references :form, index: true, foreign_key: { to_table: :forms }
      t.references :created_by, index: true, foreign_key: { to_table: :users }
      t.references :last_modified_by, index: true, foreign_key: { to_table: :users }
      t.string :name
      t.string :description
      t.integer :position, null: false
      t.jsonb :data, null: false, default: {}
      t.boolean :required, default: false, null: false
      t.boolean :allow_not_applicable, default: false, null: false
      t.string :uid

      t.timestamps
    end
  end
end
