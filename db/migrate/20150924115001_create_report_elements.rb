class CreateReportElements < ActiveRecord::Migration[4.2]
  def change
    create_table :report_elements do |t|
      t.integer :position, null: false
      t.integer :type_of, null: false
      t.integer :sort_order, default: 0 # Can be null

      # Each element belongs to report
      t.integer :report_id

      # Each element can have parent element
      t.references :parent, index: true

      # References to various report entities
      t.integer :project_id
      t.integer :my_module_id
      t.integer :step_id
      t.integer :result_id
      t.integer :checklist_id
      t.integer :asset_id
      t.integer :table_id

      t.timestamps null: false
    end

    add_foreign_key :report_elements, :reports
    add_index :report_elements, :report_id

    add_foreign_key :report_elements, :projects
    add_index :report_elements, :project_id
    add_foreign_key :report_elements, :my_modules
    add_index :report_elements, :my_module_id
    add_foreign_key :report_elements, :steps
    add_index :report_elements, :step_id
    add_foreign_key :report_elements, :results
    add_index :report_elements, :result_id
    add_foreign_key :report_elements, :checklists
    add_index :report_elements, :checklist_id
    add_foreign_key :report_elements, :assets
    add_index :report_elements, :asset_id
    add_foreign_key :report_elements, :tables
    add_index :report_elements, :table_id
  end
end
