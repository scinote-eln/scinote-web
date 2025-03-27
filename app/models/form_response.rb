# frozen_string_literal: true

class InvalidStatusError < StandardError; end

class FormResponse < ApplicationRecord
  include Discard::Model

  default_scope -> { kept }

  belongs_to :form
  belongs_to :created_by, class_name: 'User'
  belongs_to :submitted_by, class_name: 'User', optional: true

  has_one :step_orderable_element, as: :orderable, dependent: :destroy

  enum :status, { pending: 0, submitted: 1, locked: 2 }

  has_many :form_field_values, dependent: :destroy

  belongs_to :previous_form_response,
             -> { unscope(where: :discarded_at) },
             class_name: 'FormResponse',
             inverse_of: :next_form_response,
             optional: true,
             dependent: :destroy

  has_one  :next_form_response,
           class_name: 'FormResponse',
           foreign_key: 'previous_form_response_id',
           inverse_of: :previous_form_response,
           dependent: :destroy

  def step
    step_orderable_element&.step
  end

  def parent
    step_orderable_element&.step
  end

  def create_value!(created_by, form_field, value, not_applicable: false)
    ActiveRecord::Base.transaction(requires_new: true) do
      current_form_field_value = form_field_values.where(latest: true).last

      form_field_values.where(form_field: form_field).find_each do |form_field_value|
        form_field_value.update!(latest: false)
      end

      new_form_field_value = "Form#{form_field.data['type']}Value".constantize.new(
        form_field: form_field,
        form_response: self,
        # these can change if the form_response is reset, as submitted_by will be kept the same, but created_by will change
        created_by: created_by,
        submitted_by: created_by,
        submitted_at: DateTime.current,
        not_applicable: not_applicable
      )

      # for RepositoryRowsField we need to directly set previous data to the new value,
      # before save, to perserve existing repository row snapshots
      new_form_field_value.data = current_form_field_value&.data if form_field.data['type'] == 'RepositoryRowsField'

      new_form_field_value.update!(value: value)

      new_form_field_value
    end
  end

  def submit!(user)
    update!(
      status: :submitted,
      submitted_by: user,
      submitted_at: DateTime.current
    )
  end

  def reset!(user)
    raise InvalidStatusError, 'Cannot reset form that has not been submitted yet!' if status != 'submitted'

    ActiveRecord::Base.transaction(requires_new: true) do
      new_form_response = dup
      new_form_response.update!(status: 'pending', created_by: user, previous_form_response: self)

      form_field_values.latest.find_each do |form_field_value|
        form_field_value.dup.update!(form_response: new_form_response, created_by: user)
      end

      # if attached to step, reattach new form response

      discard

      self&.step_orderable_element&.update!(orderable: new_form_response)

      new_form_response
    end
  end

  def duplicate(parent, user, position = nil)
    ActiveRecord::Base.transaction do
      new_form_response = FormResponse.create!(
        status: :pending,
        form_id: form_id,
        discarded_at: nil,
        submitted_by: nil,
        created_by_id: user.id
      )

      parent.step_orderable_elements.create!(
        position: position || parent.step_orderable_elements.length,
        orderable: new_form_response
      )

      new_form_response
    end
  end
end
