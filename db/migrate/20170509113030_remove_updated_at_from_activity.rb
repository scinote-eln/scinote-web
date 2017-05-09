class RemoveUpdatedAtFromActivity < ActiveRecord::Migration
  def change
    remove_column :activities, :updated_at, :datetime
  end
end
