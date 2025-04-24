# frozen_string_literal: true

class AddManagementColumnsToProjectAndExperiment < ActiveRecord::Migration[7.0]
  include DatabaseHelper

  def change
    add_column :projects, :started_at, :datetime
    add_column :projects, :completed_at, :datetime
    add_column :projects, :start_on, :date
    add_column :projects, :description, :text
    add_reference :projects, :supervised_by, foreign_key: { to_table: :users }

    add_column :experiments, :started_at, :datetime
    add_column :experiments, :completed_at, :datetime
    add_column :experiments, :due_date, :date
    add_column :experiments, :start_on, :date

    reversible do |dir|
      dir.up do
        change_column :projects, :due_date, :date
        add_gin_index_without_tags(:projects, :description)
      end
      dir.down do
        change_column :projects, :due_date, :datetime
        remove_index :projects, name: 'index_projects_on_description'
      end
    end
  end
end
