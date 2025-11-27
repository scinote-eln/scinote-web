# frozen_string_literal: true

class ResultText < ApplicationRecord
  include TinyMceImages
  include SearchableModel
  include ObservableModel
  include ActionView::Helpers::TextHelper

  SEARCHABLE_ATTRIBUTES = ['result_texts.name', 'result_texts.text'].freeze

  auto_strip_attributes :name, nullify: false
  validates :name, length: { maximum: Constants::NAME_MAX_LENGTH }
  auto_strip_attributes :text, nullify: false
  validates :text, length: { maximum: Constants::RICH_TEXT_MAX_LENGTH }

  belongs_to :result, inverse_of: :result_texts, touch: true, class_name: 'ResultBase'
  has_one :result_orderable_element, as: :orderable, dependent: :destroy

  delegate :team, to: :result

  def duplicate(result, position = nil)
    ActiveRecord::Base.transaction do
      new_result_text = result.result_texts.create!(
        text: text,
        name: name
      )

      case result
      when Result
        team = result.my_module.team
      when ResultTemplate
        team = result.protocol.team
      end

      # Copy results tinyMce assets
      clone_tinymce_assets(new_result_text, team)

      result.result_orderable_elements.create!(
        position: position || result.result_orderable_elements.length,
        orderable: new_result_text
      )

      new_result_text
    end
  end

  private

  # Override for ObservableModel
  def changed_by
    result.last_modified_by || result.user
  end
end
