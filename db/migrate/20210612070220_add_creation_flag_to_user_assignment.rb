class AddCreationFlagToUserAssignment < ActiveRecord::Migration[6.1]
  def change
    add_column :user_assignments, :assigned, :integer, null: false, default: 0
  end
end
