# frozen_string_literal: true

class AddDocxPreviewProcessingToReports < ActiveRecord::Migration[6.1]
  def change
    add_column :reports, :docx_preview_processing, :boolean, default: false, null: false
  end
end
