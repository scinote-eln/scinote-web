# frozen_string_literal: true
module StepElements
  class FormResponsesController < BaseController
    before_action :load_form, only: :create
    before_action :load_parent, only: :create
    before_action :load_form_response, except: :create

    def create
      render_403 and return unless can_create_protocol_form_responses?(@parent.protocol)
      ActiveRecord::Base.transaction do
        @form_response = FormResponse.create!(form: @form, created_by: current_user)
        @parent.step_orderable_elements.create!(orderable: @form_response)
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

      render_step_orderable_element(@form_response)
    end

    private

    def form_response_params
      params.permit(:form_id, :step_id)
    end

    def load_form
      @form = Form.find_by(id: form_response_params[:form_id])

      render_404 unless @form && can_read_form?(@form)
    end

    def load_parent
      @parent = Step.find_by(id: form_response_params[:step_id])
      render_404 unless @parent
    end

    def load_form_response
      @form_response = FormResponse.find_by(id: params[:id])

      render_404 unless @form_response
    end
  end
end
