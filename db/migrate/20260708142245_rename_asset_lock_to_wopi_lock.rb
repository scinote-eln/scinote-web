class RenameAssetLockToWopiLock < ActiveRecord::Migration[7.2]
  def change
    rename_column :assets, :lock, :wopi_lock
    rename_column :assets, :lock_ttl, :wopi_lock_ttl
  end
end
