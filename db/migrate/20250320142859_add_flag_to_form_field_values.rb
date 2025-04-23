# frozen_string_literal: true

class AddFlagToFormFieldValues < ActiveRecord::Migration[7.0]
  def change
    add_column :form_field_values, :flag, :boolean
  end
end
