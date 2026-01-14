# frozen_string_literal: true

class AddSkippedAtToSteps < ActiveRecord::Migration[7.2]
  def change
    add_column :steps, :skipped_at, :datetime
  end
end
