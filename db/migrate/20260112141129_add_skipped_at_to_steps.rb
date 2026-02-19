# frozen_string_literal: true

class AddSkippedAtToSteps < ActiveRecord::Migration[7.2]
  STEP_STATE_ACTIVITY_TYPE_IDS = Extends::ACTIVITY_TYPES.values_at(:complete_step, :uncomplete_step).freeze

  def up
    add_column :steps, :skipped_at, :datetime

    execute <<~SQL.squish
      UPDATE activities
      SET values = jsonb_set(values, '{"message_items", "num_skipped"}', '"0"'::jsonb)
      WHERE type_of IN (#{STEP_STATE_ACTIVITY_TYPE_IDS.join(',')})
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
