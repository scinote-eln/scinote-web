# frozen_string_literal: true

class AddDateAndDateToToFormFieldValues < ActiveRecord::Migration[7.2]
  # rubocop:disable Rails/SkipsModelValidations
  def up
    add_column :form_field_values, :date, :date
    add_column :form_field_values, :date_to, :date

    FormDatetimeFieldValue.joins(:form_field).where.not('form_fields.data ? :key', key: 'time').find_each do |form_datetime_field_value|
      form_datetime_field_value.update_columns(
        date: form_datetime_field_value.datetime&.utc&.to_date,
        date_to: form_datetime_field_value.datetime_to&.utc&.to_date,
        datetime: nil,
        datetime_to: nil
      )
    end
  end

  def down
    FormDatetimeFieldValue.joins(:form_field).where.not('form_fields.data ? :key', key: 'time').find_each do |form_datetime_field_value|
      form_datetime_field_value.update_columns(
        datetime: form_datetime_field_value.date&.to_datetime,
        datetime_to: form_datetime_field_value.date_to&.to_datetime
      )
    end

    remove_column :form_field_values, :date, :date
    remove_column :form_field_values, :date_to, :date
  end
  # rubocop:enable Rails/SkipsModelValidations
end
