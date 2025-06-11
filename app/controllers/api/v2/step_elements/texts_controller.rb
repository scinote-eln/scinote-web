# frozen_string_literal: true

module Api
  module V2
    module StepElements
      class TextsController < ::Api::V1::StepTextsController
        private

        def step_text_params
          raise TypeError unless params.require(:data).require(:type) == 'step_texts'

          params.require(:data).require(:attributes).permit(:name, :text)
        end
      end
    end
  end
end
