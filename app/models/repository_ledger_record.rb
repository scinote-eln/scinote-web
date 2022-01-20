# frozen_string_literal: true

class RepositoryLedgerRecord < ApplicationRecord
  belongs_to :repository_stock_value, optional: true
  belongs_to :reference, polymorphic: true
  belongs_to :user
end
