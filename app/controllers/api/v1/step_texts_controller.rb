# frozen_string_literal: true

module Api
  module V1
    class StepTextsController < BaseController
      before_action :load_team, :load_project, :load_experiment, :load_task, :load_protocol, :load_step
      before_action only: %i(show update destroy) do
        load_step_text(:id)
      end
      before_action :check_create_permissions, only: :create
      before_action :check_manage_permissions, only: :update
      before_action :check_delete_permissions, only: :destroy

      def index
        step_texts = timestamps_filter(@step.step_texts)
        step_texts = archived_filter(step_texts, default_to_active: true)
        step_texts = step_texts.page(params.dig(:page, :number)).per(params.dig(:page, :size))

        render jsonapi: step_texts, each_serializer: StepTextSerializer, include: include_params
      end

      def show
        render jsonapi: @step_text, serializer: StepTextSerializer, include: include_params
      end

      def create
        step_text = @step.step_texts.new(step_text_params)
        @step.with_lock do
          step_text.save!
          @step.step_orderable_elements.create!(
            position: @step.next_element_position,
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

      def check_create_permissions
        raise PermissionError.new(StepText, :create) unless can_manage_step?(@step)
      end

      def check_manage_permissions
        raise PermissionError.new(StepText, :manage) unless can_manage_step_text?(@step_text)
      end

      def check_delete_permissions
        raise PermissionError.new(StepText, :delete) unless can_delete_step_text?(@step_text)
      end
    end
  end
end
