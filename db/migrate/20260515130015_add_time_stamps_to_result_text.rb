# frozen_string_literal: true

class AddTimeStampsToResultText < ActiveRecord::Migration[7.2]
  def up
    add_timestamps :result_texts, null: true

    execute <<~SQL.squish
      UPDATE result_texts
      SET created_at = COALESCE(subquery.roe_created_at, subquery.result_created_at),
          updated_at = COALESCE(subquery.roe_updated_at, subquery.result_updated_at)
      FROM (
        SELECT result_texts.id,
               roe.created_at AS roe_created_at,
               roe.updated_at AS roe_updated_at,
               r.created_at AS result_created_at,
               r.updated_at AS result_updated_at
        FROM result_texts
        LEFT JOIN result_orderable_elements roe
          ON roe.orderable_id = result_texts.id AND roe.orderable_type = 'ResultText'
        LEFT JOIN results r ON result_texts.result_id = r.id
      ) subquery
      WHERE result_texts.id = subquery.id;
    SQL

    change_column_null :result_texts, :created_at, false
    change_column_null :result_texts, :updated_at, false
  end

  def down
    remove_timestamps :result_texts
  end
end
