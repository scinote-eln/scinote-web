# frozen_string_literal: true

class UpdateRepositoryLedgerRecords < ActiveRecord::Migration[7.0]
  def up
    add_column :repository_ledger_records, :unit, :string

    execute('
      UPDATE repository_ledger_records
      SET balance = repository_ledger_records.balance + repository_ledger_records.amount
      FROM (
        SELECT *, ROW_NUMBER() OVER(PARTITION BY repository_stock_value_id ORDER BY created_at) AS row_number
        FROM repository_ledger_records
        WHERE reference_type = \'RepositoryBase\'
      ) with_row_numbers
      WHERE repository_ledger_records.id = with_row_numbers.id AND with_row_numbers.row_number != 1;

      UPDATE repository_ledger_records SET comment = NULL WHERE comment = \'\';
    ')
  end

  def down
    execute('
      UPDATE repository_ledger_records
      SET balance = repository_ledger_records.balance - repository_ledger_records.amount
      FROM (
        SELECT *, ROW_NUMBER() OVER(PARTITION BY repository_stock_value_id ORDER BY created_at) AS row_number
        FROM repository_ledger_records
        WHERE reference_type = \'RepositoryBase\'
      ) with_row_numbers
      WHERE repository_ledger_records.id = with_row_numbers.id AND with_row_numbers.row_number != 1;
    ')

    remove_column :repository_ledger_records, :unit
  end
end
