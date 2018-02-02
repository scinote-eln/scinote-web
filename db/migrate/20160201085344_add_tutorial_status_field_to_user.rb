class AddTutorialStatusFieldToUser < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :tutorial_status, :integer, default: 0

    # We assume all present users already ran the intro tutorial
    User.update_all(tutorial_status: 1)

    change_column_null :users, :tutorial_status, false
  end

  def down
    remove_column :users, :tutorial_status
  end
end
