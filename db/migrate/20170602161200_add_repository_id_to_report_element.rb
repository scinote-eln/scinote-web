class AddRepositoryIdToReportElement < ActiveRecord::Migration
  def change
    add_column :report_elements, :repository_id, :integer
    add_index :report_elements, :repository_id
  end
end
