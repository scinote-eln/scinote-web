# frozen_string_literal: true

class AddMetadataToProjects < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :metadata, :jsonb
  end
end
