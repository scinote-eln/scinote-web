class AddIndexToUsersFullName < ActiveRecord::Migration
  def change
    add_index :users, :full_name
  end
end
