class AddIndexesToConnections < ActiveRecord::Migration
  def change
    add_index :connections, :input_id
    add_index :connections, :output_id
  end
end
