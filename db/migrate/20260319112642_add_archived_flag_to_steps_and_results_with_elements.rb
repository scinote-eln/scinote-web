# frozen_string_literal: true

class AddArchivedFlagToStepsAndResultsWithElements < ActiveRecord::Migration[7.2]
  def change
    change_column_null :steps, :position, true

    %i(steps assets checklists tables form_responses step_texts result_texts).each do |table|
      add_column table, :archived, :boolean, default: false, null: false
      add_column table, :archived_on, :datetime
      add_column table, :restored_on, :datetime
      add_reference table, :archived_by, foreign_key: { to_table: :users }, null: true
      add_reference table, :restored_by, foreign_key: { to_table: :users }, null: true

      add_index table, :archived
    end
  end
end
