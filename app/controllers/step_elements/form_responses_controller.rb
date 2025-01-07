# frozen_string_literal: true

module StepElements
  class FormResponsesController < BaseController
    before_action :load_form, only: :create
    before_action :load_step, only: :create
    before_action :load_form_response, except: :create
    skip_before_action :check_manage_permissions, only: %i(submit reset)

    def create
      render_403 and return unless can_create_protocol_form_responses?(@step.protocol)

      ActiveRecord::Base.transaction do
        @form_response = FormResponse.create!(form: @form, created_by: current_user)
        create_in_step!(@step, @form_response)
      end

      render_step_orderable_element(@form_response)
    end

    def submit
      render_403 and return unless can_submit_form_response?(@form_response)

      @form_response.submit!(current_user)

      render_step_orderable_element(@form_response)
    end

    def reset
      render_403 and return unless can_reset_form_response?(@form_response)

      new_form_response = @form_response.reset!(current_user)

      render_step_orderable_element(new_form_response)
    end

    private

    def form_response_params
      params.permit(:form_id, :step_id)
    end

    def load_form
      @form = Form.find_by(id: form_response_params[:form_id])

      render_404 unless @form && can_read_form?(@form)
    end

    def load_step
      @step = Step.find_by(id: form_response_params[:step_id])

      render_404 unless @step
    end

    def load_form_response
      @form_response = FormResponse.find_by(id: params[:id])

      render_404 unless @form_response
    end
  end
end
