# frozen_string_literal: true

class AddPinnedAtToResults < ActiveRecord::Migration[7.2]
  def change
    add_column :results, :pinned_at, :datetime
    add_reference :results, :pinned_by, foreign_key: { to_table: :users }
  end
end
