# frozen_string_literal: true

module StepComponents
  class ChecklistsController < BaseController
    before_action :load_checklist, only: %i(update destroy)

    def create
      checklist = @step.checklists.build(
        name: t('protocols.steps.checklist.default_name', position: @step.checklists.length + 1)
      )

      create_in_step!(@step, checklist)
      render_step_orderable_element(checklist)
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def update
      @checklist.update!(checklist_params)
      render json: @checklist, serializer: ChecklistSerializer
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def destroy
      if @checklist.destroy
        head :ok
      else
        head :unprocessable_entity
      end
    end

    private

    def checklist_params
      params.permit(:name, :text)
    end

    def load_checklist
      @checklist = @step.checklists.find_by(id: params[:id])
      return render_404 unless @checklist
    end
  end
end
