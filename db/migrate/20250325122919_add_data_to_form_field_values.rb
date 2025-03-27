# frozen_string_literal: true

class AddDataToFormFieldValues < ActiveRecord::Migration[7.0]
  def change
    add_column :form_field_values, :data, :jsonb
  end
end
