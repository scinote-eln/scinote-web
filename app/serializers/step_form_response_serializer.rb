# frozen_string_literal: true

class StepFormResponseSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers

  attributes :id, :created_at, :form_id, :urls, :submitted_by_full_name, :status, :submitted_at, :parent_type, :in_repository

  has_one :form, serializer: FormSerializer

  has_many :form_fields, serializer: FormFieldSerializer do
    object.form.form_fields
  end

  has_many :form_field_values do
    object.form_field_values.latest
  end

  def parent_type
    :step
  end

  def in_repository
    !object.step.protocol.my_module
  end

  def submitted_by_full_name
    object.submitted_by&.full_name
  end

  def submitted_at
    I18n.l(object.submitted_at, format: :full) if object.submitted_at
  end

  def urls
    user = scope[:user] || @instance_options[:user]

    list = {
      add_value: form_response_form_field_values_path(object)
    }

    list[:submit] = submit_step_form_response_path(object.step, object) if can_submit_form_response?(user, object)
    list[:reset] = reset_step_form_response_path(object.step, object) if can_reset_form_response?(user, object)
    if can_manage_step?(user, object.step)
      list[:move_url] = move_step_form_response_path(object.step, object)
      list[:move_targets_url] = move_targets_step_text_path(object.step, object)
      list[:delete_url] = step_form_response_path(object.step, object)
    end

    list
  end
end
