# frozen_string_literal: true

class AddTypeToZipExports < ActiveRecord::Migration[5.1]
  def change
    add_column :zip_exports, :type, :string
  end
end
