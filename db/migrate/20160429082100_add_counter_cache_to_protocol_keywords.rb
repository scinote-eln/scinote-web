class AddCounterCacheToProtocolKeywords < ActiveRecord::Migration[4.2]
  def up
    add_column :protocol_keywords, :nr_of_protocols, :integer, default: 0

    # Okay, now initialize the values of synced children
    ProtocolKeyword.find_each do |kw|
      kw.update(nr_of_protocols: kw.protocols.count)
    end
  end

  def down
    remove_column :protocol_keywords, :nr_of_protocols
  end
end
