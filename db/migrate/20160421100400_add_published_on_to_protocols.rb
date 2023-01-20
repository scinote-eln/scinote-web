class AddPublishedOnToProtocols < ActiveRecord::Migration[4.2]
  def up
    add_column :protocols, :published_on, :datetime
  end

  def down
    remove_column :protocols, :published_on
  end
end
