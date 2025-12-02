# frozen_string_literal: true

class StepOrderableElement < ApplicationRecord
  include ObservableModel

  validates :position, uniqueness: { scope: :step }
  validate :check_step_relations

  belongs_to :step, inverse_of: :step_orderable_elements, touch: true
  belongs_to :orderable, polymorphic: true, inverse_of: :step_orderable_element
  {
    step_text: 'StepText',
    step_table: 'StepTable',
    checklist: 'Checklist',
    form_response: 'FormResponse'
  }.each do |relation, class_name|
    belongs_to :"#{relation}",
               (lambda do |step_orderable_element|
                 step_orderable_element.orderable_type == class_name ? self : none
               end),
               optional: true, foreign_key: :orderable_id, inverse_of: :step_orderable_element, class_name: class_name
  end

  around_destroy :decrement_following_elements_positions

  private

  def check_step_relations
    if step != orderable.step
      errors.add(
        :step_orderable_element,
        I18n.t('activerecord.errors.models.step_orderable_element.attributes.step.wrong_step')
      )
    end
  end

  def decrement_following_elements_positions
    step.with_lock do
      yield
      step.normalize_elements_position
    end
  end

  # Override for ObservableModel
  def changed_by
    step.last_modified_by
  end
end
