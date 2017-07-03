class AddIndexToSampleName < ActiveRecord::Migration[4.2]
  def change
    add_index :samples, :name
  end
end
