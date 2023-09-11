# frozen_string_literal: true

class RepositoryLedgerRecord < ApplicationRecord
  auto_strip_attributes :comment

  belongs_to :repository_stock_value
  belongs_to :reference, polymorphic: true
  belongs_to :user
  belongs_to :repository,
             (lambda do |repository_ledger_record|
               repository_ledger_record.reference_type == 'RepositoryBase' ? self : none
             end),
             optional: true, foreign_key: :reference_id, inverse_of: :repository_ledger_records
  belongs_to :my_module_repository_row,
             (lambda do |repository_ledger_record|
               repository_ledger_record.reference_type == 'MyModuleRepositoryRow' ? self : none
             end),
             optional: true, foreign_key: :reference_id, inverse_of: :repository_ledger_records
  has_one :repository_row, through: :repository_stock_value
end
