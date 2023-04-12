# frozen_string_literal: true

module StepElements
  class TablesController < BaseController
    before_action :load_table, only: %i(update destroy duplicate)

    def create
      step_table = @step.step_tables.new(table:
        Table.new(
          name: t('protocols.steps.table.default_name', position: @step.step_tables.length + 1),
          contents: { data: Array.new(5, Array.new(5, '')) }.to_json,
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
          @table.metadata = JSON.parse(table_params[:metadata]) if table_params[:metadata].present?
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

    def load_table
      @table = @step.tables.find_by(id: params[:id])
      return render_404 unless @table
    end
  end
end
