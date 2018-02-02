class AddExperimentsOrderToProjects < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :experiments_order, :string
  end
end
