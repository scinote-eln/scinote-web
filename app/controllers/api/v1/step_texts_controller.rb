# frozen_string_literal: true

module Api
  module V1
    class StepTextsController < BaseController
      before_action :load_team, :load_project, :load_experiment, :load_task, :load_protocol, :load_step
      before_action only: :show do
        load_step_text(:id)
      end
      before_action :load_step_text_for_managing, only: %i(update destroy)

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

      def destroy
        @step_text.destroy!
        render body: nil
      end

      private

      def step_text_params
        raise TypeError unless params.require(:data).require(:type) == 'step_texts'

        params.require(:data).require(:attributes).permit(:text)
      end

      def permitted_includes
        %w(step_text_items)
      end

      def load_step_text_for_managing
        @step_text = @step.step_texts.find(params.require(:id))
        raise PermissionError.new(Protocol, :manage) unless can_manage_protocol_in_module?(@protocol)
      end
    end
  end
end
