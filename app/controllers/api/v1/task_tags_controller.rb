# frozen_string_literal: true

module Api
  module V1
    class TaskTagsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :load_task
      before_action :load_tag, only: :show

      def index
        tags = timestamps_filter(@task.tags).page(params.dig(:page, :number))
                                            .per(params.dig(:page, :size))
        render jsonapi: tags, each_serializer: TagSerializer
      end

      def show
        render jsonapi: @tag, serializer: TagSerializer
      end

      private

      def load_tag
        @tag = @task.tags.find(params.require(:id))
      end
    end
  end
end
