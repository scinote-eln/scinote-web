class AddCounterCacheToProtocols < ActiveRecord::Migration[4.2]
  class TempProtocol < ApplicationRecord
    self.table_name = 'protocols'
  end

  def up
    add_column :protocols, :nr_of_synced_children, :integer, default: 0

    # Okay, now initialize the values of synced children
    TempProtocol.find_each do |protocol|
      children_count = select_value("SELECT COUNT(*) FROM protocols WHERE parent_id=#{protocol.id};")
      protocol.update(nr_of_synced_children: children_count)
    end
  end

  def down
    remove_column :protocols, :nr_of_synced_children
  end
end
