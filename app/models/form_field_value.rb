# frozen_string_literal: true

class FormFieldValue < ApplicationRecord
  belongs_to :form_response
  belongs_to :form_field
  belongs_to :created_by, class_name: 'User'
  belongs_to :submitted_by, class_name: 'User'

  scope :latest, -> { where(latest: true) }

  def value=(_)
    raise NotImplementedError
  end

  def value
    raise NotImplementedError
  end
end
