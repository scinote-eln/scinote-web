# frozen_string_literal: true

module StepComponents
  class ChecklistsController < StepOrderableElementsController
    private

    def create_step_element
      @step.checklists.create!(
        name: t('protocols.steps.checklist.default_name', position: @step.step_tables.length + 1)
      )
    end

    def element_params
      params.require(:checklist).permit(:name)
    end
  end
end
