# frozen_string_literal: true

class FormFieldValuesController < ApplicationController
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
end
