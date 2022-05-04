# frozen_string_literal: true

module StepComponents
  class ChecklistsController < StepOrderableElementsController
    private

    def create_step_element
      @step.checklists.create!(
        name: t('protocols.steps.checklist.default_name', position: @step.checklists.length + 1)
      )
    end

    def orderable_params
      params.permit(:name)
    end

    def load_vars
      @element = @step.checklists.find_by(id: params[:id])
      @orderable_element = @element.step_orderable_elements.find_by(step: @step)
      return render_404 unless @element && @orderable_element
    end
  end
end
