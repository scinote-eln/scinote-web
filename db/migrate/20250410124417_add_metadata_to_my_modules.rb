# frozen_string_literal: true

class AddMetadataToMyModules < ActiveRecord::Migration[7.0]
  def change
    add_column :my_modules, :metadata, :jsonb
  end
end
