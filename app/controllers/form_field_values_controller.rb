# frozen_string_literal: true

class FormFieldValuesController < ApplicationController
  include ApplicationHelper
  before_action :check_forms_enabled
  before_action :load_form_response
  before_action :load_form_field
  before_action :check_create_permissions

  def create
    @form_field_value = @form_response.create_value!(
      current_user,
      @form_field,
      form_field_value_params[:value],
      not_applicable: form_field_value_params[:not_applicable]
    )

    log_form_field_value_create_activity
    form_field_value_annotation if @form_field_value.is_a?(FormTextFieldValue)

    render json: @form_field_value, serializer: FormFieldValueSerializer, user: current_user
  end

  private

  def form_field_value_params
    params.require(:form_field_value).permit(:form_field_id, :value, :not_applicable, value: [])
  end

  def load_form_response
    @form_response = FormResponse.find_by(id: params[:form_response_id])

    render_404 unless @form_response
  end

  def load_form_field
    @form_field = @form_response.form.form_fields.find_by(id: form_field_value_params[:form_field_id])

    render_404 unless @form_field
  end

  def check_create_permissions
    render_403 unless can_submit_form_response?(@form_response)
  end

  def check_forms_enabled
    render_404 unless Form.forms_enabled?
  end

  def form_field_value_annotation
    step = @form_response.step
    smart_annotation_notification(
      old_text: @form_field_value.text_previously_was,
      new_text: @form_field_value.text,
      subject: step.protocol,
      title: t('notifications.form_field_value_title',
               user: current_user.full_name,
               field: @form_field_value.form_field.name,
               step: step.name)
    )
  end

  def log_form_field_value_create_activity
    step = @form_response.step
    protocol = step.protocol

    Activities::CreateActivityService.call(
      activity_type: :task_step_form_field_edited,
      owner: current_user,
      team: protocol.team,
      project: nil,
      subject: protocol,
      message_items: {
        user: current_user.id,
        form_field_name: @form_field.name,
        form: @form_field.form.id,
        step: step.id,
        step_position: {
          id: step.id,
          value_for: 'position_plus_one'
        },
        my_module: protocol.my_module.id
      }
    )
  end
end
