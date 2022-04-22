# frozen_string_literal: true

class StepText < ApplicationRecord
  include TinyMceImages

  auto_strip_attributes :text, nullify: false
  validates :text, presence: true
  validates :text, length: { maximum: Constants::RICH_TEXT_MAX_LENGTH }

  belongs_to :step, inverse_of: :step_texts, touch: true
  has_many :step_orderable_elements, as: :orderable, dependent: :destroy
end
