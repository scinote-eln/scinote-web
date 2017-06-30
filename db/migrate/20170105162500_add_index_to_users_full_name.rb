class AddIndexToUsersFullName < ActiveRecord::Migration[4.2]
  def change
    add_index :users, :full_name
  end
end
