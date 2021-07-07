# frozen_string_literal: true

class AddReportTemplateValues < ActiveRecord::Migration[6.1]
  def change
    create_table :report_template_values do |t|
      t.references :report, null: false, index: true, foreign_key: true
      t.string :view_component, null: false
      t.string :name, null: false
      t.jsonb :value, null: false, default: {}
      t.timestamps

      t.index %i(view_component name), name: 'index_report_template_values_on_view_component_name'
    end
  end
end
