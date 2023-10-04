# frozen_string_literal: true

module ResultElements
  class TablesController < BaseController
    before_action :load_table, only: %i(update destroy duplicate move)

    def create
      predefined_table_dimensions = create_table_params[:tableDimensions].map(&:to_i)
      name = if predefined_table_dimensions[0] == predefined_table_dimensions[1]
               t('protocols.steps.table.default_name',
                 position: @result.result_tables.length + 1)
             else
               t('protocols.steps.plate.default_name',
                 position: @result.result_tables.length + 1)
             end
      result_table = @result.result_tables.new(table:
        Table.new(
          name: name,
          contents: { data: Array.new(predefined_table_dimensions[0],
                                      Array.new(predefined_table_dimensions[1], '')) }.to_json,
          metadata: { plateTemplate: create_table_params[:plateTemplate] == 'true' },
          created_by: current_user,
          team: @my_module.team
        ))

      ActiveRecord::Base.transaction do
        create_in_result!(@result, result_table)
        log_result_activity(:result_table_added, { table_name: result_table.table.name })
      end

      render_result_orderable_element(result_table)
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def update
      ActiveRecord::Base.transaction do
        @table.assign_attributes(table_params.except(:metadata))
        begin
          if table_params[:metadata].present?

            @table.metadata = if @table.metadata
                                @table.metadata.merge(JSON.parse(table_params[:metadata]))
                              else
                                JSON.parse(table_params[:metadata])
                              end
          end
        rescue JSON::ParserError
          @table.metadata = {}
        end
        @table.save!
        log_result_activity(:result_table_edited, { table_name: @table.name })
      end

      render json: @table, serializer: ResultTableSerializer, user: current_user
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def move
      target = @my_module.results.active.find_by(id: params[:target_id])
      return head(:conflict) unless target

      result_table = @table.result_table

      ActiveRecord::Base.transaction do
        result_table.update!(result: target)
        result_table.result_orderable_element.destroy
        new_orderable_element = target.result_orderable_elements.build(orderable: result_table)
        new_orderable_element.insert_at(target.result_orderable_elements.count)
        @result.normalize_elements_position

        log_result_activity(
          :result_table_moved,
          {
            user: current_user.id,
            table_name: @table.name,
            result_original: @result.id,
            result_destination: target.id
          }
        )

        render json: @table, serializer: ResultTableSerializer, user: current_user
      rescue ActiveRecord::RecordInvalid
        render json: result_table.errors, status: :unprocessable_entity
      end
    end

    def destroy
      if @table.destroy
        log_result_activity(:result_table_deleted, { table_name: @table.name })
        head :ok
      else
        head :unprocessable_entity
      end
    end

    def duplicate
      ActiveRecord::Base.transaction do
        position = @table.result_table.result_orderable_element.position
        @result.result_orderable_elements.where('position > ?', position).order(position: :desc).each do |element|
          element.update(position: element.position + 1)
        end
        @table.name += ' (1)'
        new_table = @table.duplicate(@result, current_user, position + 1)
        log_result_activity(:result_table_duplicated, { table_name: new_table.name })
        render_result_orderable_element(new_table.result_table)
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace.join("\n"))
      head :unprocessable_entity
    end

    private

    def table_params
      params.permit(:name, :contents, :metadata)
    end

    def create_table_params
      params.permit(:plateTemplate, tableDimensions: [])
    end

    def load_table
      @table = @result.tables.find_by(id: params[:id])
      return render_404 unless @table
    end
  end
end
