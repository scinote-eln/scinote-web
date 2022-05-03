# frozen_string_literal: true

module StepComponents
  class TextsController < StepOrderableElementsController
    private

    def create_step_element
      @step.step_texts.create!
    end

    def element_params
      params.require(:step_text).permit(:text)
    end
  end
end
