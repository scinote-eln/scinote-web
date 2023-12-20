# frozen_string_literal: true

module Api
  module V2
    module StepElements
      class TextsController < ::Api::V1::StepTextsController
        def index
          step_texts = timestamps_filter(@step.step_texts).page(params.dig(:page, :number))
                                                          .per(params.dig(:page, :size))

          render jsonapi: step_texts, each_serializer: StepTextSerializer, include: include_params
        end

        def show
          render jsonapi: @step_text, serializer: StepTextSerializer, include: include_params
        end

        def create
          raise PermissionError.new(Protocol, :create) unless can_manage_protocol_in_module?(@protocol)

          step_text = @step.step_texts.new(step_text_params)
          @step.with_lock do
            step_text.save!
            @step.step_orderable_elements.create!(
              position: @step.step_orderable_elements.size,
              orderable: step_text
            )
          end

          render jsonapi: step_text, serializer: StepTextSerializer, status: :created
        end

        def update
          @step_text.assign_attributes(step_text_params)

          if @step_text.changed? && @step_text.save!
            render jsonapi: @step_text, serializer: StepTextSerializer, status: :ok
          else
            render body: nil, status: :no_content
          end
        end

        private

        def step_text_params
          raise TypeError unless params.require(:data).require(:type) == 'texts'

          params.require(:data).require(:attributes).permit(:text)
        end
      end
    end
  end
end
