# frozen_string_literal: true

class CreateFormFieldValues < ActiveRecord::Migration[7.0]
  def change
    create_table :form_field_values do |t|
      t.string :type, index: true
      t.references :form_response, null: false, foreign_key: true
      t.references :form_field, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :submitted_by, null: true, foreign_key: { to_table: :users }
      t.timestamp :submitted_at
      t.boolean :latest, null: false, default: true
      t.boolean :not_applicable, null: false, default: false

      # FormFieldDateTimeValue
      t.datetime :datetime
      t.datetime :datetime_to

      # FormFieldNumberValue
      t.decimal :number
      t.decimal :number_to
      t.text :unit

      # FormFieldTextValue, FormFieldSingleChoiceValue
      t.text :text

      # FormFieldMultipleCohiceValue
      t.text :selection, array: true

      t.timestamps
    end
  end
end
