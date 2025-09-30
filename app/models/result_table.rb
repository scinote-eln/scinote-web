# frozen_string_literal: true

class ResultTable < ApplicationRecord
  belongs_to :result, inverse_of: :result_tables, touch: true, optional: true
  belongs_to :result_template, inverse_of: :result_tables, optional: true
  belongs_to :table, inverse_of: :result_table, dependent: :destroy, touch: true
  has_one :result_orderable_element, as: :orderable, dependent: :destroy

  validates :result_id, presence: true, unless: :result_template_id
  validates :result_template_id, presence: true, unless: :result_id

  def result_or_template
    result_template || result
  end
end
