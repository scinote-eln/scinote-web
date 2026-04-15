# frozen_string_literal: true

class ResultTable < ApplicationRecord
  belongs_to :result, inverse_of: :result_tables, touch: true, class_name: 'ResultBase'
  belongs_to :table, inverse_of: :result_table, dependent: :destroy, touch: true
  has_one :result_orderable_element, as: :orderable, dependent: :destroy

  scope :active, lambda {
    joins(:result_orderable_element).where(result_orderable_elements: { archived: false })
  }

  scope :archived, lambda {
    joins(:result_orderable_element).where(result_orderable_elements: { archived: true })
  }
end
