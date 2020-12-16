# frozen_string_literal: true

class AddPdfPreviewProcessingFlagToAsset < ActiveRecord::Migration[6.0]
  def change
    add_column :assets, :pdf_preview_processing, :boolean, default: false
  end
end
