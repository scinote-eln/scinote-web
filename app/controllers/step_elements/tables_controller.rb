# frozen_string_literal: true

module StepElements
  class TablesController < BaseController
    before_action :load_table, only: %i(update destroy)

    def create
      step_table = @step.step_tables.new(table:
        Table.new(
          name: t('protocols.steps.table.default_name', position: @step.step_tables.length + 1),
          contents: { data: Array.new(5, Array.new(5, '')) }.to_json,
          created_by: current_user
        ))

      create_in_step!(@step, step_table)

      render_step_orderable_element(step_table)
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def update
      @table.update!(table_params)
      render json: @table, serializer: TableSerializer
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def destroy
      if @table.destroy
        head :ok
      else
        head :unprocessable_entity
      end
    end

    def table_params
      params.permit(:name, :contents)
    end

    def load_table
      @table = @step.tables.find_by(id: params[:id])
      return render_404 unless @table
    end
  end
end
