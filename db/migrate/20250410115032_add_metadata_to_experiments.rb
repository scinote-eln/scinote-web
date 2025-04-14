# frozen_string_literal: true

class AddMetadataToExperiments < ActiveRecord::Migration[7.0]
  def change
    add_column :experiments, :metadata, :jsonb
  end
end
