# frozen_string_literal: true

class AddArchiveToSteps < ActiveRecord::Migration[7.2]
  def change
    add_column :step_orderable_elements, :archived, :boolean, default: false, null: false
    add_column :step_orderable_elements, :archived_on, :datetime
    add_column :step_orderable_elements, :restored_on, :datetime
    add_reference :step_orderable_elements, :archived_by, foreign_key: { to_table: :users }, null: true
    add_reference :step_orderable_elements, :restored_by, foreign_key: { to_table: :users }, null: true

    add_index :step_orderable_elements, :archived

    change_column_null :steps, :position, true
    add_column :steps, :archived, :boolean, default: false, null: false
    add_column :steps, :archived_on, :datetime
    add_column :steps, :restored_on, :datetime
    add_reference :steps, :archived_by, foreign_key: { to_table: :users }, null: true
    add_reference :steps, :restored_by, foreign_key: { to_table: :users }, null: true

    add_index :steps, :archived
  end
end
