# frozen_string_literal: true

module Api
  module V1
    class WorkflowStatusesController < BaseController
      before_action :load_workflow

      def index
        statuses = filter_timestamp_range(@workflow.my_module_statuses)
        render jsonapi: statuses, each_serializer: WorkflowStatusSerializer
      end
    end
  end
end
