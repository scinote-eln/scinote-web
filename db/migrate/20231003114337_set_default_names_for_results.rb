# frozen_string_literal: true

class SetDefaultNamesForResults < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.connection.execute(
      "UPDATE result_texts SET name = results.name
        FROM results
        WHERE result_texts.result_id = results.id
        AND (result_texts.name = '' OR result_texts.name IS NULL)
        AND results.name IS NOT NULL AND results.name != '' AND results.name != 'Untitled result'"
    )

    ActiveRecord::Base.connection.execute(
      "UPDATE tables SET name = results.name
        FROM results
        INNER JOIN result_tables ON results.id = result_tables.result_id
        WHERE result_tables.table_id = tables.id
        AND (tables.name = '' OR tables.name IS NULL)
        AND results.name IS NOT NULL AND results.name != ''"
    )

    ActiveRecord::Base.connection.execute(
      "UPDATE results SET name = 'Untitled result' WHERE results.name = '' OR results.name IS NULL"
    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
