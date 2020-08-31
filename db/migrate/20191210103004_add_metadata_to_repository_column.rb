# frozen_string_literal: true

class AddMetadataToRepositoryColumn < ActiveRecord::Migration[6.0]
  def change
    add_column :repository_columns, :metadata, :jsonb, default: {}, null: false
  end
end
