class RemoveLogsTable < ActiveRecord::Migration[4.2]
  def change
    drop_table :logs
  end
end
