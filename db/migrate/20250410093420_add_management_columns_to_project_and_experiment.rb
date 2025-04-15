# frozen_string_literal: true

class AddManagementColumnsToProjectAndExperiment < ActiveRecord::Migration[7.0]
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
      dir.up { change_column :projects, :due_date, :date }
      dir.down { change_column :projects, :due_date, :datetime }
    end
  end
end
