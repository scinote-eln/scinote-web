# frozen_string_literal: true

module Api
  module V2
    module ResultElements
      class TablesController < BaseController
        before_action :load_team, :load_project, :load_experiment, :load_task, :load_result
        before_action only: %i(show update destroy) do
          load_result_table(:id)
        end
        before_action :check_manage_permission, only: %i(create update destroy)

        def index
          result_tables = timestamps_filter(@result.result_tables).page(params.dig(:page, :number))
                                                                  .per(params.dig(:page, :size))

          render jsonapi: result_tables, each_serializer: ResultTableSerializer
        end

        def show
          render jsonapi: @table.result_table, serializer: ResultTableSerializer
        end

        def create
          table = @result.tables.new(table_params.merge!(team: @team, created_by: current_user))

          @result.with_lock do
            @result.result_orderable_elements.create!(
              position: @result.result_orderable_elements.size,
              orderable: table.result_table
            )

            table.save!
          end

          render jsonapi: table.result_table, serializer: ResultTableSerializer, status: :created
        end

        def update
          @table.assign_attributes(table_params)

          if @table.changed? && @table.save!
            render jsonapi: @table.result_table, serializer: ResultTableSerializer
          else
            render body: nil, status: :no_content
          end
        end

        def destroy
          @table.destroy!
          render body: nil
        end

        private

        def check_manage_permission
          raise PermissionError.new(Result, :manage) unless can_manage_result?(@result)
        end

        def convert_plate_template(metadata_params)
          if metadata_params.present? && metadata_params['plateTemplate']
            metadata_params['plateTemplate'] = ActiveRecord::Type::Boolean.new.cast(metadata_params['plateTemplate'])
          end
        end

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
end
