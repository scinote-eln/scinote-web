# frozen_string_literal: true

module StepElements
  class TablesController < BaseController
    before_action :load_table, only: %i(update destroy duplicate move)

    def create
      predefined_table_dimensions = create_table_params[:tableDimensions].map(&:to_i)
      name = if predefined_table_dimensions[0] == predefined_table_dimensions[1]
               t('protocols.steps.table.default_name',
                 position: @step.step_tables.length + 1)
             else
               t('protocols.steps.plate.default_name',
                 position: @step.step_tables.length + 1)
             end
      step_table = @step.step_tables.new(table:
        Table.new(
          name: name,
          contents: { data: Array.new(predefined_table_dimensions[0],
                                      Array.new(predefined_table_dimensions[1], '')) }.to_json,
          metadata: { plateTemplate: create_table_params[:plateTemplate] == 'true' },
          created_by: current_user,
          team: @step.protocol.team
        ))

      ActiveRecord::Base.transaction do
        create_in_step!(@step, step_table)
        log_step_activity(:table_added, { table_name: step_table.table.name })
      end

      render_step_orderable_element(step_table)
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
        log_step_activity(:table_edited, { table_name: @table.name })
      end

      render json: @table, serializer: TableSerializer, user: current_user
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def move
      target = @protocol.steps.find_by(id: params[:target_id])
      step_table = @table.step_table
      ActiveRecord::Base.transaction do
        step_table.update!(step: target)
        step_table.step_orderable_element.update!(step: target, position: target.step_orderable_elements.size)
        @step.normalize_elements_position
        render json: @table, serializer: TableSerializer, user: current_user

        log_step_activity(
          :table_moved,
          {
            user: current_user.id,
            table_name: @table.name,
            step_position_original: @step.position + 1,
            step_original: @step.id,
            step_position_destination: target.position + 1,
            step_destination: target.id
          }
        )

      rescue ActiveRecord::RecordInvalid
        render json: step_table.errors, status: :unprocessable_entity
      end
    end

    def destroy
      if @table.destroy
        log_step_activity(:table_deleted, { table_name: @table.name })
        head :ok
      else
        head :unprocessable_entity
      end
    end

    def duplicate
      ActiveRecord::Base.transaction do
        position = @table.step_table.step_orderable_element.position
        @step.step_orderable_elements.where('position > ?', position).order(position: :desc).each do |element|
          element.update(position: element.position + 1)
        end
        @table.name += ' (1)'
        new_table = @table.duplicate(@step, current_user, position + 1)
        log_step_activity(:table_duplicated, { table_name: new_table.name })
        render_step_orderable_element(new_table.step_table)
      end
    rescue ActiveRecord::RecordInvalid
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
      @table = @step.tables.find_by(id: params[:id])
      return render_404 unless @table
    end
  end
end
