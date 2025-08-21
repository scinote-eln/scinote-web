# frozen_string_literal: true

class FormFieldValue < ApplicationRecord
  include ObservableModel

  belongs_to :form_response
  belongs_to :form_field
  belongs_to :created_by, class_name: 'User'
  belongs_to :submitted_by, class_name: 'User'

  validate :not_applicable_values
  validate :uniqueness_latest, if: :latest?

  scope :latest, -> { where(latest: true) }

  def value=(_)
    raise NotImplementedError
  end

  def value
    raise NotImplementedError
  end

  def formatted
    value
  end

  def value_in_range?
    true
  end

  def name
    form_field&.name
  end

  private

  def not_applicable_values
    return unless not_applicable

    errors.add(:value, :not_applicable) if value.present?
  end

  def uniqueness_latest
    return unless form_response&.form_field_values&.exists?(form_field_id: form_field_id, latest: true)

    errors.add(:value, :not_unique_latest)
  end

  # Override for ObservableModel
  def changed_by
    created_by
  end
end
