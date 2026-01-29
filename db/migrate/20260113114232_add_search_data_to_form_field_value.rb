# frozen_string_literal: true

require File.expand_path('app/helpers/database_helper')

class AddSearchDataToFormFieldValue < ActiveRecord::Migration[7.2]
  include DatabaseHelper

  def up
    add_column :form_field_values, :search_data, :text

    add_gin_index_without_tags(:form_field_values, :search_data)

    FormFieldValue.reset_column_information

    FormFieldValue.where(latest: true).find_each do |value|
      value.set_search_data
      value.update_column(:search_data, value.search_data)
    end
  end

  def down
    remove_index :form_field_values, name: :index_form_field_values_on_search_data
    remove_column :form_field_values, :search_data
  end
end
