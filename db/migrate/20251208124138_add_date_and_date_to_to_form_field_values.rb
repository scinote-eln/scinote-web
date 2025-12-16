# frozen_string_literal: true

class AddDateAndDateToToFormFieldValues < ActiveRecord::Migration[7.2]
  def up
    add_column :form_field_values, :date, :date
    add_column :form_field_values, :date_to, :date

    FormDatetimeFieldValue.joins(:form_field).where.not('form_fields.data ? :key', key: 'time').find_each do |form_datetime_field_value|
      form_datetime_field_value.date = form_datetime_field_value.datetime&.utc&.to_date
      form_datetime_field_value.date_to = form_datetime_field_value.datetime_to&.utc&.to_date
      form_datetime_field_value.datetime = nil
      form_datetime_field_value.datetime_to = nil
      form_datetime_field_value.save(validate: false)
    end
  end

  def down
    FormDatetimeFieldValue.joins(:form_field).where.not('form_fields.data ? :key', key: 'time').find_each do |form_datetime_field_value|
      form_datetime_field_value.datetime = form_datetime_field_value.date&.to_datetime
      form_datetime_field_value.datetime_to = form_datetime_field_value.date_to&.to_datetime
      form_datetime_field_value.save(validate: false)
    end

    remove_column :form_field_values, :date, :date
    remove_column :form_field_values, :date_to, :date
  end
end
