# frozen_string_literal: true

class Token < ApplicationRecord
  validates :token, presence: true
  validates :ttl, presence: true

  belongs_to :user, inverse_of: :tokens
end
