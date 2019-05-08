# frozen_string_literal: true

class CreateMarvinJsAssets < ActiveRecord::Migration[5.1]
  def change
    create_table :marvin_js_assets do |t|
      t.bigint :team_id
      t.string :description
      t.references :object, polymorphic: true

      t.timestamps
    end

    change_column :marvin_js_assets, :id, :bigint
  end
end
