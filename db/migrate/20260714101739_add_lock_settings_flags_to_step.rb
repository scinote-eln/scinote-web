class AddLockSettingsFlagsToStep < ActiveRecord::Migration[7.2]
  def change
    add_column :steps, :adding_items_allowed, :boolean, default: true, null: false
    add_index :steps, :adding_items_allowed

    add_column :steps, :attachments_locked, :boolean, default: false, null: false
    add_index :steps, :attachments_locked
  end
end
