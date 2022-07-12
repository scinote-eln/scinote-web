# frozen_string_literal: true

class StepOrderableElement < ApplicationRecord
  validates :position, uniqueness: { scope: :step }
  validate :check_step_relations

  around_destroy :decrement_following_elements_positions

  belongs_to :step, inverse_of: :step_orderable_elements, touch: true
  belongs_to :orderable, polymorphic: true, inverse_of: :step_orderable_elements

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
      step.step_orderable_elements.where('position > ?', position).find_each do |step_orderable_element|
        step_orderable_element.position -= 1
        step_orderable_element.save!
      end
    end
  end
end
