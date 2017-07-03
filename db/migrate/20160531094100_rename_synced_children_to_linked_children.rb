class RenameSyncedChildrenToLinkedChildren < ActiveRecord::Migration[4.2]
  def up
    rename_column :protocols, :nr_of_synced_children, :nr_of_linked_children
  end

  def down
    rename_column :protocols, :nr_of_linked_children, :nr_of_synced_children
  end
end
