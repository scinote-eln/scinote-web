# frozen_string_literal: true

class RemoveUnusedReferencesFromTinyMceAssets < ActiveRecord::Migration[6.0]
  def change
    remove_reference :tiny_mce_assets, :result_text, index: true
    remove_reference :tiny_mce_assets, :step, index: true
  end
end
