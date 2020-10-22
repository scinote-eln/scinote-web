# frozen_string_literal: true

class CreateTaskFlowsModels < ActiveRecord::Migration[6.0]
  def change
    change_table :my_modules do |t|
      t.references :my_module_status
    end

    create_table :my_module_status_flows do |t|
      t.string :name, null: false
      t.string :description
      t.integer :visibility, index: true, default: 0
      t.references :team
      t.references :created_by, index: false, foreign_key: { to_table: :users }
      t.references :last_modified_by, index: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    create_table :my_module_statuses do |t|
      t.string :name, null: false
      t.string :description
      t.string :color, null: false
      t.references :my_module_status_flow, index: true
      t.references :previous_status, index: { unique: true }, foreign_key: { to_table: :my_module_statuses }
      t.references :created_by, index: false, foreign_key: { to_table: :users }
      t.references :last_modified_by, index: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    create_table :my_module_status_consequences do |t|
      t.references :my_module_status
      t.string :type

      t.timestamps
    end

    create_table :my_module_status_conditions do |t|
      t.references :my_module_status
      t.string :type

      t.timestamps
    end

    create_table :my_module_status_implications do |t|
      t.references :my_module_status
      t.string :type

      t.timestamps
    end
  end
end
