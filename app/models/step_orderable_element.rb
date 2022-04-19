# frozen_string_literal: true

class StepOrderableElement < ApplicationRecord
  validates :position, uniqueness: { scope: :step }
  validate :check_step_relations

  around_destroy :decrement_following_elements_positions

  belongs_to :step, inverse_of: :step_orderable_elements, touch: true
  belongs_to :orderable, polymorphic: true, inverse_of: :step_orderable_elements

  def move_to(new_position)
    moved = false
    step.with_lock do
      old_position = position
      update_column(position: -1)
      if new_position > old_position
        step.step_orderable_elements
            .where('position > ? AND position =< ?', old_position, new_position)
            .update_all('position = position - 1')
      else
        step.step_orderable_elements
            .where('position => ? AND position < ?', new_position, old_position)
            .update_all('position = position + 1')
      end
      update_column(position: new_position)
      moved = true
    end
    moved
  end

  private

  def check_step_relations
    if step != orderable.step
      errors.add(
        :step_orderable_element,
        I18n.t('activerecord.errors.models.step_orderable_elements.attributes.step.wrong_step')
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
