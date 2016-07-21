class ReportGroupingRemoval < ActiveRecord::Migration
  def up  
    remove_column :reports, :grouped_by
  end

  def down
    add_column :reports, :grouped_by, :integer, :null => false, :default => 0
  end
end
