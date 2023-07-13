class AddWorkflowOrderToMyModules < ActiveRecord::Migration[4.2]
  def up
    add_column :my_modules, :workflow_order, :integer, null: false, default: -1
  end

  def down
    remove_column :my_modules, :workflow_order
  end
end
