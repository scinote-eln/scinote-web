# frozen_string_literal: true

module StepElements
  class TextsController < BaseController
    include ApplicationHelper
    include StepsActions

    before_action :load_step_text, only: %i(update destroy duplicate move)

    def create
      step_text = @step.step_texts.build

      ActiveRecord::Base.transaction do
        create_in_step!(@step, step_text)
        log_step_activity(:text_added, { text_name: step_text.name })
      end

      render_step_orderable_element(step_text)
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def update
      old_text = @step_text.text
      ActiveRecord::Base.transaction do
        @step_text.update!(step_text_params)
        TinyMceAsset.update_images(@step_text, params[:tiny_mce_images], current_user)
        log_step_activity(:text_edited, { text_name: @step_text.name })
        step_text_annotation(@step, @step_text, old_text)
      end

      render json: @step_text, serializer: StepTextSerializer, user: current_user
    rescue ActiveRecord::RecordInvalid
      render json: @step_text.errors, status: :unprocessable_entity
    end

    def move
      target = @protocol.steps.find_by(id: params[:target_id])
      ActiveRecord::Base.transaction do
        @step_text.update!(step: target)
        @step_text.step_orderable_element.update!(step: target, position: target.step_orderable_elements.size)
        @step.normalize_elements_position

        log_step_activity(
          :text_moved,
          {
            user: current_user.id,
            text_name: @step_text.name,
            step_position_original: @step.position + 1,
            step_original: @step.id,
            step_position_destination: target.position + 1,
            step_destination: target.id
          }
        )

        render json: @step_text, serializer: StepTextSerializer, user: current_user
      rescue ActiveRecord::RecordInvalid
        render json: @step_text.errors, status: :unprocessable_entity
      end
    end

    def destroy
      if @step_text.destroy
        log_step_activity(:text_deleted, { text_name: @step_text.name })
        head :ok
      else
        head :unprocessable_entity
      end
    end

    def duplicate
      ActiveRecord::Base.transaction do
        position = @step_text.step_orderable_element.position
        @step.step_orderable_elements.where('position > ?', position).order(position: :desc).each do |element|
          element.update(position: element.position + 1)
        end
        new_step_text = @step_text.duplicate(@step, position + 1)
        log_step_activity(:text_duplicated, { text_name: new_step_text.name })
        render_step_orderable_element(new_step_text)
      end
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    private

    def step_text_params
      params.require(:text_component).permit(:text, :name)
    end

    def load_step_text
      @step_text = @step.step_texts.find_by(id: params[:id])
      return render_404 unless @step_text
    end
  end
end
