# frozen_string_literal: true

module Api
  module V1
    class WorkflowsController < BaseController
      before_action only: :show do
        load_workflow(:id)
      end

      def index
        workflows = filter_timestamp_range(MyModuleStatusFlow.all)
        render jsonapi: workflows, each_serializer: WorkflowSerializer
      end

      def show
        render jsonapi: @workflow, serializer: WorkflowSerializer
      end
    end
  end
end
