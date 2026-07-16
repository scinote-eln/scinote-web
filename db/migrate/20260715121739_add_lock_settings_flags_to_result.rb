class AddLockSettingsFlagsToResult < ActiveRecord::Migration[7.2]
  def change
    add_column :results, :attachments_locked, :boolean, default: false, null: false
    add_index :results, :attachments_locked
  end
end
