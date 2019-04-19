# frozen_string_literal: true
class AddPolymorphicToTinyMceAsset < ActiveRecord::Migration[5.1]
  def change
    add_reference :tiny_mce_assets, :object, polymorphic: true
  end
end
