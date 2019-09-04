# frozen_string_literal: true

class ConvertActivitiesJsonToJsonb < ActiveRecord::Migration[5.2]
  def change
    change_column :activities, :values, 'jsonb USING CAST(values AS jsonb)'
    ActiveRecord::Base.connection.execute("
      UPDATE activities SET values = REGEXP_REPLACE(values::text, '^\"||\"$||\\\\', '', 'g')::jsonb
    ")
  end
end
