# frozen_string_literal: true

class AddAnalyticalReports < ActiveRecord::Migration[7.2]
  def change
    create_table :report_templates do |t|
      t.string :name
      t.references :subject, polymorphic: true, null: false
      t.timestamps
    end

    create_table :my_module_reports do |t|
      t.string :name
      t.references :my_module, index: true, foreign_key: true
      t.timestamps
    end
  end
end
