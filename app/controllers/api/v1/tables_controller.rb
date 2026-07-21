# frozen_string_literal: true

module Api
  module V1
    class TablesController < BaseController
      before_action :load_team, :load_project, :load_experiment, :load_task, :load_protocol, :load_step
      before_action only: %i(show update destroy) do
        load_table(:id)
      end
      before_action :check_create_permissions, only: :create
      before_action :check_manage_permissions, only: :update
      before_action :check_delete_permissions, only: :destroy

      def index
        tables = timestamps_filter(@step.tables)
        tables = archived_filter(tables, default_to_active: true)
        tables = tables.page(params.dig(:page, :number))
                                                .per(params.dig(:page, :size))

        render jsonapi: tables, each_serializer: TableSerializer
      end

      def show
        render jsonapi: @table, serializer: TableSerializer
      end

      def create
        table = @step.tables.new(table_params.merge!(team: @team, created_by: current_user))
        @step.with_lock do
          table.save!
          @step.step_orderable_elements.create!(
            position: @step.next_element_position,
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

        attributes_params = params.require(:data).require(:attributes).permit(
          :name,
          :contents,
          metadata: [
            :plateTemplate,
            { cells: %i(col row className) }
          ]
        )

        convert_plate_template(attributes_params[:metadata])
        validate_metadata_params(attributes_params)
        attributes_params
      end

      def check_create_permissions
        raise PermissionError.new(Table, :create) unless can_manage_step?(@step)
      end

      def check_manage_permissions
        raise PermissionError.new(Table, :manage) unless can_manage_step_table?(@table)
      end

      def check_delete_permissions
        raise PermissionError.new(Table, :delete) unless can_delete_step_table?(@table)
      end

      def convert_plate_template(metadata_params)
        if metadata_params.present? && metadata_params['plateTemplate']
          metadata_params['plateTemplate'] = ActiveRecord::Type::Boolean.new.cast(metadata_params['plateTemplate'])
        end
      end

      def validate_metadata_params(attributes_params)
        metadata = attributes_params[:metadata]
        contents = JSON.parse(attributes_params[:contents] || '{}')

        if metadata.present? && metadata[:cells].present? && contents.present?
          metadata_cells = metadata[:cells]
          data = contents['data']

          if data.present? && data[0].present?
            data_size = (data[0].is_a?(Array) ? data.size * data[0].size : data.size)

            if data_size < metadata_cells.size
              error_message = I18n.t('api.core.errors.table.metadata.detail_too_many_cells')
              raise ActionController::BadRequest, error_message
            end
          end
        end
      end
    end
  end
end
