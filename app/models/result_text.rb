# frozen_string_literal: true

class ResultText < ApplicationRecord
  include TinyMceImages

  auto_strip_attributes :text, nullify: false
  validates :text, length: { maximum: Constants::RICH_TEXT_MAX_LENGTH }

  belongs_to :result, inverse_of: :result_texts, touch: true
  has_one :result_orderable_element, as: :orderable, dependent: :destroy
end
