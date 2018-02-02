class AddPublishedOnToProtocols < ActiveRecord::Migration[4.2]
  def up
    add_column :protocols, :published_on, :datetime

    Protocol.where(protocol_type: :in_repository_public).find_each do |p|
      p.update_column(:published_on, p.created_at)
    end
  end

  def down
    remove_column :protocols, :published_on
  end
end
