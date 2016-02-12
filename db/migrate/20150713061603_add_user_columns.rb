class AddUserColumns < ActiveRecord::Migration
  def up
    add_attachment :users, :avatar
  end

  def down
    remove_attachment :users, :avatar
  end
end
