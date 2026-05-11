# frozen_string_literal: true

class StepText < ApplicationRecord
  include TinyMceImages
  include ObservableModel
  include SearchableModel
  include ArchivableModel
  include ActionView::Helpers::TextHelper

  SEARCHABLE_ATTRIBUTES = ['step_texts.name', 'step_texts.text'].freeze

  auto_strip_attributes :name, nullify: false
  validates :name, length: { maximum: Constants::NAME_MAX_LENGTH }
  auto_strip_attributes :text, nullify: false
  validates :text, length:
    {
      maximum:
       ENV['STEP_TEXT_MAX_LENGTH'].present? ? ENV['STEP_TEXT_MAX_LENGTH'].to_i : Constants::RICH_TEXT_MAX_LENGTH
    }

  belongs_to :step, inverse_of: :step_texts, touch: true
  belongs_to :archived_by, class_name: 'User', optional: true
  belongs_to :restored_by, class_name: 'User', optional: true
  has_one :step_orderable_element, as: :orderable, dependent: :destroy

  delegate :team, to: :step

  after_save :manage_orderable_element_on_archive, if: -> { saved_change_to_archived? }

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
        position: position || step.next_element_position,
        orderable: new_step_text
      )

      new_step_text
    end
  end

  private

  # Override for ObservableModel
  def changed_by
    step.last_modified_by
  end

  def manage_orderable_element_on_archive
    if archived?
      step_orderable_element&.destroy
    elsif step_orderable_element.blank?
      create_step_orderable_element!(step: step, position: step.next_element_position)
    end
  end
end
