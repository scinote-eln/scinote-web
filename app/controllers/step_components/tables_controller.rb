# frozen_string_literal: true

module StepComponents
  class TablesController < StepOrderableElementsController
    private

    def create_step_element
      @step.step_tables.create!(table:
        Table.create!(
          name: t('protocols.steps.table.default_name', position: @step.step_tables.length + 1),
          contents: '{"data":[["",""],["",""],["",""],["",""],["",""]]}',
          created_by: current_user
        ))
    end

    def element_params
      params.require(:table).permit(:name, :contents)
    end

    def load_vars
      @element = @step.tables.find_by(id: params[:id])
      @orderable_element = @element.step_table.step_orderable_elements.find_by(step: @step)
      return render_404 unless @element && @orderable_element
    end
  end
end
