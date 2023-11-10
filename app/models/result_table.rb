# frozen_string_literal: true

class ResultTable < ApplicationRecord
  belongs_to :result, inverse_of: :result_tables
  belongs_to :table, inverse_of: :result_table, dependent: :destroy, touch: true
  has_one :result_orderable_element, as: :orderable, dependent: :destroy
end
