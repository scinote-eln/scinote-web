# frozen_string_literal: true

class RepositoryLedgerRecord < ApplicationRecord
  auto_strip_attributes :comment

  belongs_to :repository_stock_value
  belongs_to :reference, polymorphic: true
  belongs_to :user
  has_one :repository_row, through: :repository_stock_value
end
