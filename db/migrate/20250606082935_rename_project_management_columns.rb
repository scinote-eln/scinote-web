# frozen_string_literal: true

class RenameProjectManagementColumns < ActiveRecord::Migration[7.0]
  def change
    rename_column :projects, :start_on, :start_date
    rename_column :projects, :completed_at, :done_at

    rename_column :experiments, :start_on, :start_date
    rename_column :experiments, :completed_at, :done_at
  end
end
