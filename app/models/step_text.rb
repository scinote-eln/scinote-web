# frozen_string_literal: true

class StepText < ApplicationRecord
  include TinyMceImages
  include ActionView::Helpers::TextHelper

  auto_strip_attributes :text, nullify: false
  validates :text, length: { maximum: Constants::RICH_TEXT_MAX_LENGTH }

  belongs_to :step, inverse_of: :step_texts, touch: true
  has_many :step_orderable_elements, as: :orderable, dependent: :destroy

  def name
    return if text.blank?

    strip_tags(text.truncate(64))
  end
end
