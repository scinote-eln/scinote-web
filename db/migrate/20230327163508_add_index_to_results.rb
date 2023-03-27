class AddIndexToResults < ActiveRecord::Migration[6.1]
  def change
    add_index :results, :archived
  end
end
