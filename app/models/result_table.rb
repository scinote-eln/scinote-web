# frozen_string_literal: true

class ResultTable < ApplicationRecord
  validates :result, :table, presence: true

  belongs_to :result, inverse_of: :result_table
  belongs_to :table, inverse_of: :result_table, dependent: :destroy, touch: true
end
