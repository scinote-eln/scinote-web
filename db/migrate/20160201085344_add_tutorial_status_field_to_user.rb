class AddTutorialStatusFieldToUser < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :tutorial_status, :integer, default: 0
    change_column_null :users, :tutorial_status, false
  end

  def down
    remove_column :users, :tutorial_status
  end
end
