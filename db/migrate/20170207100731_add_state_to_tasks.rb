class AddStateToTasks < ActiveRecord::Migration[4.2]
  def up
    add_column :my_modules,
               :state,
               :integer,
               limit: 1,
               default: 0
    add_column :my_modules,
               :completed_on,
               :datetime,
               null: true
  end

  def down
    remove_column :my_modules, :state
    remove_column :my_modules, :completed_on
  end
end
