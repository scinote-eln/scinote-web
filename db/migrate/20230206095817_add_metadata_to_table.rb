# frozen_string_literal: true

class AddMetadataToTable < ActiveRecord::Migration[6.1]
  def change
    add_column :tables, :metadata, :jsonb
  end
end
