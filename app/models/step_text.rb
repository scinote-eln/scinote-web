# frozen_string_literal: true

class StepText < ApplicationRecord
  include TinyMceImages
  include ActionView::Helpers::TextHelper

  auto_strip_attributes :name, nullify: false
  validates :name, length: { maximum: Constants::NAME_MAX_LENGTH }
  auto_strip_attributes :text, nullify: false
  validates :text, length:
    {
      maximum:
       ENV['STEP_TEXT_MAX_LENGTH'].present? ? ENV['STEP_TEXT_MAX_LENGTH'].to_i : Constants::RICH_TEXT_MAX_LENGTH
    }

  belongs_to :step, inverse_of: :step_texts, touch: true
  has_one :step_orderable_element, as: :orderable, dependent: :destroy

  scope :asc, -> { order('step_texts.created_at ASC') }

  def duplicate(step, position = nil)
    ActiveRecord::Base.transaction do
      new_step_text = step.step_texts.create!(
        text: text,
        name: name
      )

      # Copy steps tinyMce assets
      clone_tinymce_assets(new_step_text, step.protocol.team)

      step.step_orderable_elements.create!(
        position: position || step.step_orderable_elements.length,
        orderable: new_step_text
      )

      new_step_text
    end
  end
end
