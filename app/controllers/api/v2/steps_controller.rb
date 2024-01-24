# frozen_string_literal: true

module Api
  module V2
    class StepsController < ::Api::V1::StepsController
      def index
        steps = timestamps_filter(@protocol.steps).page(params.dig(:page, :number))
                                                  .per(params.dig(:page, :size))

        render jsonapi: steps, each_serializer: Api::V2::StepSerializer,
               include: include_params,
               rte_rendering: render_rte?,
               team: @team
      end

      def show
        render jsonapi: @step, serializer: Api::V2::StepSerializer,
               include: include_params,
               rte_rendering: render_rte?,
               team: @team
      end

      def create
        raise PermissionError.new(Protocol, :create) unless can_manage_protocol_in_module?(@protocol)

        @protocol.transaction do
          @step = @protocol.steps.create!(
            step_params.merge!(completed: false,
                               user: current_user,
                               position: @protocol.number_of_steps,
                               last_modified_by_id: current_user.id)
          )
        end
        render jsonapi: @step, serializer: Api::V2::StepSerializer, status: :created
      end

      def update
        @step.assign_attributes(
          step_params.merge!(last_modified_by_id: current_user.id)
        )

        if @step.changed? && @step.save!
          if @step.saved_change_to_attribute?(:completed)
            completed_steps = @protocol.steps.where(completed: true).count
            all_steps = @protocol.steps.count
            type_of = @step.saved_change_to_attribute(:completed).last ? :complete_step : :uncomplete_step
            log_activity(type_of, my_module: @task.id,
                                  num_completed: completed_steps.to_s,
                                  num_all: all_steps.to_s)
          end
          render jsonapi: @step, serializer: Api::V2::StepSerializer, status: :ok
        else
          render body: nil, status: :no_content
        end
      end

      private

      def step_params
        raise TypeError unless params.require(:data).require(:type) == 'steps'

        params.require(:data).require(:attributes).permit(:name, :completed)
      end
    end
  end
end
