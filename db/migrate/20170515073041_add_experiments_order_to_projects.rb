class AddExperimentsOrderToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :experiments_order, :string
  end
end
