# frozen_string_literal: true

module Api
  module V1
    class TablesController < BaseController
      before_action :load_team, :load_project, :load_experiment, :load_task, :load_protocol, :load_step
      before_action only: :show do
        load_table(:id)
      end
      before_action :load_table_for_managing, only: %i(update destroy)

      def index
        tables = @step.tables.page(params.dig(:page, :number)).per(params.dig(:page, :size))

        render jsonapi: tables, each_serializer: TableSerializer
      end

      def show
        render jsonapi: @table, serializer: TableSerializer
      end

      def create
        raise PermissionError.new(Protocol, :create) unless can_manage_protocol_in_module?(@protocol)

        table = @step.tables.new(table_params.merge!(team: @team, created_by: current_user))
        @step.with_lock do
          table.save!
          @step.step_orderable_elements.create!(
            position: @step.step_orderable_elements.size,
            orderable: table.step_table
          )
        end

        render jsonapi: table, serializer: TableSerializer, status: :created
      end

      def update
        @table.assign_attributes(table_params)

        if @table.changed? && @table.save!
          render jsonapi: @table, serializer: TableSerializer, status: :ok
        else
          render body: nil, status: :no_content
        end
      end

      def destroy
        @table.destroy!
        render body: nil
      end

      private

      def table_params
        raise TypeError unless params.require(:data).require(:type) == 'tables'

        params.require(:data).require(:attributes).permit(:name, :contents)
      end

      def load_table_for_managing
        @table = @step.tables.find(params.require(:id))
        raise PermissionError.new(Protocol, :manage) unless can_manage_protocol_in_module?(@protocol)
      end
    end
  end
end
