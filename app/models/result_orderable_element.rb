# frozen_string_literal: true

class ResultOrderableElement < ApplicationRecord
  include ObservableModel

  validate :check_result_relations

  validates :position, uniqueness: { scope: %i(result_id result_template_id) }

  around_destroy :decrement_following_elements_positions

  belongs_to :result, inverse_of: :result_orderable_elements, touch: true, optional: true
  belongs_to :result_template, inverse_of: :result_orderable_elements, optional: true
  belongs_to :orderable, polymorphic: true, inverse_of: :result_orderable_element

  validates :result_id, presence: true, unless: :result_template_id
  validates :result_template_id, presence: true, unless: :result_id

  def result_or_template
    result_template || result
  end

  private

  def check_result_relations
    if result != orderable.result
      errors.add(
        :step_orderable_element,
        I18n.t('activerecord.errors.models.result_orderable_element.attributes.result.wrong_result')
      )
    end
  end

  def decrement_following_elements_positions
    result.with_lock do
      yield
      result.normalize_elements_position
    end
  end

  # Override for ObservableModel
  def changed_by
    result.last_modified_by || result.user if result
  end
end
