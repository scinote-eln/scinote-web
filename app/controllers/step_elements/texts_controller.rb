# frozen_string_literal: true

module StepElements
  class TextsController < BaseController
    before_action :load_step_text, only: %i(update destroy)

    def create
      step_text = @step.step_texts.build
      create_in_step!(@step, step_text)
      render_step_orderable_element(step_text)
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def update
      @step_text.update!(step_text_params)
      TinyMceAsset.update_images(@step_text, params[:tiny_mce_images], current_user)
      render json: @step_text, serializer: StepTextSerializer
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def destroy
      if @step_text.destroy
        head :ok
      else
        head :unprocessable_entity
      end
    end

    private

    def step_text_params
      params.require(:step_text).permit(:text)
    end

    def load_step_text
      @step_text = @step.step_texts.find_by(id: params[:id])
      return render_404 unless @step_text
    end
  end
end
