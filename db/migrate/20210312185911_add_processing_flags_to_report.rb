# frozen_string_literal: true

class AddProcessingFlagsToReport < ActiveRecord::Migration[6.1]
  def change
    change_table :reports, bulk: true do |t|
      t.integer :pdf_file_status, default: 0
      t.integer :docx_file_status, default: 0
    end
  end
end
