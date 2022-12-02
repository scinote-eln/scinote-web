# frozen_string_literal: true

module StepElements
  class ChecklistsController < BaseController
    before_action :load_checklist, only: %i(update destroy duplicate)

    def create
      checklist = @step.checklists.build(
        name: t('protocols.steps.checklist.default_name', position: @step.checklists.length + 1)
      )
      ActiveRecord::Base.transaction do
        create_in_step!(@step, checklist)
        log_step_activity(:checklist_added, { checklist_name: checklist.name })
      end
      render_step_orderable_element(checklist)
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def update
      ActiveRecord::Base.transaction do
        @checklist.update!(checklist_params)
        log_step_activity(:checklist_edited, { checklist_name: @checklist.name })
      end

      render json: @checklist, serializer: ChecklistSerializer, user: current_user
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def destroy
      if @checklist.destroy
        log_step_activity(:checklist_deleted, { checklist_name: @checklist.name })
        head :ok
      else
        head :unprocessable_entity
      end
    end

    def duplicate
      ActiveRecord::Base.transaction do
        position = @checklist.step_orderable_element.position
        @step.step_orderable_elements.where('position > ?', position).order(position: :desc).each do |element|
          element.update(position: element.position + 1)
        end
        new_checklist = @checklist.duplicate(@step, current_user, position + 1)
        log_step_activity(:checklist_duplicated, { checklist_name: @checklist.name })
        render_step_orderable_element(new_checklist)
      end
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
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
