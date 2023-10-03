# frozen_string_literal: true

class ResultText < ApplicationRecord
  include TinyMceImages
  include ActionView::Helpers::TextHelper

  auto_strip_attributes :name, nullify: false
  validates :name, length: { maximum: Constants::NAME_MAX_LENGTH }
  auto_strip_attributes :text, nullify: false
  validates :text, length: { maximum: Constants::RICH_TEXT_MAX_LENGTH }

  belongs_to :result, inverse_of: :result_texts, touch: true
  has_one :result_orderable_element, as: :orderable, dependent: :destroy

  def duplicate(result, position = nil)
    ActiveRecord::Base.transaction do
      new_result_text = result.result_texts.create!(
        text: text,
        name: name
      )

      # Copy results tinyMce assets
      clone_tinymce_assets(new_result_text, result.my_module.team)

      result.result_orderable_elements.create!(
        position: position || result.result_orderable_elements.length,
        orderable: new_result_text
      )

      new_result_text
    end
  end
end
