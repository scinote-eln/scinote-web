# frozen_string_literal: true

class AddRepositoryRowReferenceToRepositoryLedgerRecords < ActiveRecord::Migration[7.0]
  def up
    add_reference :repository_ledger_records, :repository_row, foreign_key: true

    RepositoryLedgerRecord.includes(repository_stock_value: { repository_cell: :repository_row }).find_each do |record|
      record.update(repository_row: record.repository_stock_value.repository_cell.repository_row)
    end
  end

  def down
    remove_reference :repository_ledger_records, :repository_row, foreign_key: true
  end
end
