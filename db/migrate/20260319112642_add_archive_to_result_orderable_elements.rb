# frozen_string_literal: true

class AddArchiveToResultOrderableElements < ActiveRecord::Migration[7.2]
  def change
    add_column :result_orderable_elements, :archived, :boolean, default: false, null: false
    add_column :result_orderable_elements, :archived_on, :datetime
    add_column :result_orderable_elements, :restored_on, :datetime
    add_reference :result_orderable_elements, :archived_by, foreign_key: { to_table: :users }, null: true
    add_reference :result_orderable_elements, :restored_by, foreign_key: { to_table: :users }, null: true

    add_index :result_orderable_elements, :archived
  end
end
