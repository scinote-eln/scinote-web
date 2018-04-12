class RemoveTutorialStatusFromUser < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :tutorial_status, :integer, default: 0, null: false
  end
end
