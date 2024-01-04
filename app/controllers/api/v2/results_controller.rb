# frozen_string_literal: true

module Api
  module V2
    class ResultsController < BaseController
      before_action :load_team, :load_project, :load_experiment, :load_task
      before_action only: %i(show update destroy) do
        load_result(:id)
      end
      before_action :check_create_permissions, only: :create
      before_action :check_delete_permissions, only: :destroy
      before_action :check_update_permissions, only: :update

      def index
        results = timestamps_filter(@task.results).page(params.dig(:page, :number))
                                                  .per(params.dig(:page, :size))
        render jsonapi: results, each_serializer: ResultSerializer,
               include: include_params
      end

      def show
        render jsonapi: @result, serializer: ResultSerializer,
               include: include_params
      end

      def create
        @result = Result.create!(
          user: current_user,
          my_module: @task,
          name: result_params[:name]
        )
        render jsonapi: @result, serializer: ResultSerializer
      end

      def update
        @result.assign_attributes(result_params)

        if @result.changed? && @result.save!
          render jsonapi: @result, serializer: ResultSerializer
        else
          render body: nil, status: :no_content
        end
      end

      def destroy
        @result.destroy!
        render body: nil
      end

      private

      def check_create_permissions
        raise PermissionError.new(MyModule, :manage) unless can_manage_my_module?(@task)
      end

      def check_delete_permissions
        raise PermissionError.new(Result, :delete) unless can_delete_result?(@result)
      end

      def check_update_permissions
        raise PermissionError.new(Result, :manage) unless can_manage_result?(@result)
      end

      def permitted_includes
        %w(comments result_texts tables assets)
      end

      def result_params
        raise TypeError unless params.require(:data).require(:type) == 'results'

        params.require(:data).require(:attributes).require(:name)
        params.require(:data).permit(attributes: %i(name archived))[:attributes]
      end
    end
  end
end
