require File.expand_path('app/helpers/database_helper')
include DatabaseHelper

class AddTextSearchVectorToAssetTextData < ActiveRecord::Migration[4.2]
  def change
    add_column :asset_text_data, :data_vector, :tsvector

    add_index :asset_text_data, :data_vector, using: "gin"
  end
end
