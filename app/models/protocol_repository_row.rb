# frozen_string_literal: true

class ProtocolRepositoryRow < ApplicationRecord
  belongs_to :protocol
  belongs_to :repository_row, optional: true

  validates :repository_row, uniqueness: { scope: :protocol }
end
