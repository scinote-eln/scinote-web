# frozen_string_literal: true

module StepComponents
  class TextsController < StepOrderableElementsController
    private

    def create_step_element
      @step.step_texts.create!
    end

    def orderable_params
      params.require(:step_text).permit(:text)
    end

    def load_vars
      @element = @step.step_texts.find_by(id: params[:id])
      @orderable_element = @element.step_orderable_elements.find_by(step: @step)
      return render_404 unless @element && @orderable_element
    end
  end
end
