# frozen_string_literal: true

module Api
  module V1
    class StepsController < BaseController
      before_action :load_team, :load_project, :load_experiment, :load_task, :load_protocol
      before_action only: :show do
        load_step(:id)
      end

      def index
        steps = @protocol.steps
                         .page(params.dig(:page, :number))
                         .per(params.dig(:page, :size))

        render jsonapi: steps, each_serializer: StepSerializer
      end

      def show
        render jsonapi: @step, serializer: StepSerializer
      end

      def create
        raise PermissionError.new(Protocol, :create) unless can_manage_protocol_in_module?(@protocol)

        step = @protocol.steps.create!(step_params.merge!(completed: false,
                                                          user_id: current_user.id,
                                                          position: @protocol.number_of_steps))

        render jsonapi: step,
               serializer: StepSerializer,
               status: :created
      end

      private

      def step_params
        raise TypeError unless params.require(:data).require(:type) == 'steps'

        attr_list = %i(name)
        params.require(:data).require(:attributes).require(attr_list)
        params.require(:data).require(:attributes).permit(attr_list + [:description])
      end
    end
  end
end
