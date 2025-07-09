class AddCounterCacheToProtocols < ActiveRecord::Migration[4.2]
  def up
    add_column :protocols, :nr_of_synced_children, :integer, default: 0
  end

  def down
    remove_column :protocols, :nr_of_synced_children
  end
end
