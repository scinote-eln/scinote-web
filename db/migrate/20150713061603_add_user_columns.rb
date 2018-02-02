class AddUserColumns < ActiveRecord::Migration[4.2]
  def up
    add_attachment :users, :avatar
  end

  def down
    remove_attachment :users, :avatar
  end
end
