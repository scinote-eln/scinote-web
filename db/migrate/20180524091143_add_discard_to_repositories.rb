class AddDiscardToRepositories < ActiveRecord::Migration[5.1]
  def change
    add_column :repositories, :discarded_at, :datetime
    add_index :repositories, :discarded_at
  end
end
