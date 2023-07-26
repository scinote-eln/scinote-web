# frozen_string_literal: true

class ResultOrderableElement < ApplicationRecord
  validates :position, uniqueness: { scope: :step }
  validate :check_result_relations

  around_destroy :decrement_following_elements_positions

  belongs_to :result, inverse_of: :result_orderable_elements, touch: true
  belongs_to :orderable, polymorphic: true, inverse_of: :result_orderable_element

  private

  def check_step_relations
    if step != orderable.step
      errors.add(
        :step_orderable_element,
        I18n.t('activerecord.errors.models.result_orderable_element.attributes.result.wrong_result')
      )
    end
  end

  def decrement_following_elements_positions
    result.with_lock do
      yield
      result.result_orderable_elements
            .where('position > ?', position)
            .order(position: :asc).each do |result_orderable_element|
        # find_each ignore any ordering
        result_orderable_element.position -= 1
        result_orderable_element.save!
      end
    end
  end
end
