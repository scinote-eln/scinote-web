class AddDiscardedAtToResults < ActiveRecord::Migration[7.0]
  def change
    add_column :results, :discarded_at, :datetime
    add_index :results, :discarded_at
  end
end
