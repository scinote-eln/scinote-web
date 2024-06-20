# frozen_string_literal: true

class AddDiscardedAtToActiveStorageAttachments < ActiveRecord::Migration[7.0]
  def change
    add_column :active_storage_attachments, :discarded_at, :datetime
    add_index :active_storage_attachments, :discarded_at
  end
end
