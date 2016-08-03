class AddExperimentToReportElements < ActiveRecord::Migration
  def change
    add_column :report_elements, :experiment_id, :integer

    add_foreign_key :report_elements, :experiments
    add_index :report_elements, :experiment_id
  end
end
