# frozen_string_literal: true

module Api
  module V2
    module StepElements
      class FormResponsesController < BaseController
        before_action :load_team, :load_project, :load_experiment, :load_task, :load_protocol, :load_step
        before_action :load_form_response, only: %i(show)

        def index
          form_responses = timestamps_filter(@step.form_responses).page(params.dig(:page, :number))
                                                                  .per(params.dig(:page, :size))

          render jsonapi: form_responses, each_serializer: Api::V2::FormResponseSerializer, include: include_params
        end

        def show
          render jsonapi: @form_response, serializer: Api::V2::FormResponseSerializer, include: include_params
        end

        private

        def load_form_response
          @form_response = @step.form_responses.find(params.require(:id))
        end

        def permitted_includes
          %w(form_field_values)
        end
      end
    end
  end
end
