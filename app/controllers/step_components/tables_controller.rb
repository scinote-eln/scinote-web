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
  end
end
