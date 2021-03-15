# frozen_string_literal: true

class AddProcessingFlagsToReport < ActiveRecord::Migration[6.1]
  def change
    change_table :reports, bulk: true do |t|
      t.boolean :pdf_file_processing, default: false
      t.boolean :docx_file_processing, default: false
    end
  end
end
