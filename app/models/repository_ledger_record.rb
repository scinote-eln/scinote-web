# frozen_string_literal: true

class RepositoryLedgerRecord < ApplicationRecord
  belongs_to :repository_row
  belongs_to :reference, polymorphic: true, inverse_of: :repository_ledger_record
end
