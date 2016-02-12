class AddIndexToSampleName < ActiveRecord::Migration
  def change
    add_index :samples, :name
  end
end
