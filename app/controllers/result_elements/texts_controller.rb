# frozen_string_literal: true

module ResultElements
  class TextsController < BaseController
    include ActionView::Helpers::UrlHelper
    include ApplicationHelper
    include InputSanitizeHelper
    include Rails.application.routes.url_helpers

    before_action :load_result_text, only: %i(update destroy duplicate move)

    def create
      result_text = ResultText.build

      if @result.is_a?(ResultTemplate)
        result_text.result_template = @result
      else
        result_text.result = @result
      end

      ActiveRecord::Base.transaction do
        create_in_result!(@result, result_text)
        log_result_activity(:result_text_added, { text_name: result_text.name }) if @object.is_a?(MyModule)
      end

      render_result_orderable_element(result_text)
    rescue ActiveRecord::RecordInvalid => e
      logger.error "Failed to create ResultText: #{e.message}"
      head :unprocessable_entity
    end

    def update
      old_text = @result_text.text
      ActiveRecord::Base.transaction do
        @result_text.update!(result_text_params)
        TinyMceAsset.update_images(@result_text, params[:tiny_mce_images], current_user)
        log_result_activity(:result_text_edited, { text_name: @result_text.name }) if @object.is_a?(MyModule)
        result_annotation_notification(old_text)
      end

      render json: @result_text, serializer: ResultTextSerializer, user: current_user
    rescue ActiveRecord::RecordInvalid
      render json: @result_text.errors, status: :unprocessable_entity
    end

    def move
      target = @object.results.active.find_by(id: params[:target_id])
      return head(:conflict) unless target

      ActiveRecord::Base.transaction do
        case target
        when ResultTemplate
          @result_text.update!(result_template: target)
          @result_text.result_orderable_element.update!(result_template: target, position: target.result_orderable_elements.size)
        when Result
          @result_text.update!(result: target)
          @result_text.result_orderable_element.update!(result: target, position: target.result_orderable_elements.size)
        end
        @result.normalize_elements_position
        render json: @result_text, serializer: ResultTextSerializer, user: current_user

        log_result_activity(
          :result_text_moved,
          {
            user: current_user.id,
            text_name: @result_text.name,
            result_original: @result.id,
            result_destination: target.id
          }
        ) if @object.is_a?(MyModule)
      rescue ActiveRecord::RecordInvalid
        render json: @result_text.errors, status: :unprocessable_entity
      end
    end

    def destroy
      if @result_text.destroy
        log_result_activity(:result_text_deleted, { text_name: @result_text.name })
        head :ok
      else
        head :unprocessable_entity
      end
    end

    def duplicate
      ActiveRecord::Base.transaction do
        position = @result_text.result_orderable_element.position
        @result.result_orderable_elements.where('position > ?', position).order(position: :desc).each do |element|
          element.update(position: element.position + 1)
        end
        new_result_text = @result_text.duplicate(@result, position + 1)
        log_result_activity(:result_text_duplicated, { text_name: new_result_text.name }) if @object.is_a?(MyModule)
        render_result_orderable_element(new_result_text)
      end
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    private

    def result_text_params
      params.require(:text_component).permit(:text, :name)
    end

    def load_result_text
      @result_text = @result.result_texts.find_by(id: params[:id])
      return render_404 unless @result_text
    end

    def result_annotation_notification(old_text = nil)
      smart_annotation_notification(
        old_text: old_text,
        new_text: @result_text.text,
        subject: @result,
        title: t('notifications.result_annotation_title',
                 result: @result.name,
                 user: current_user.full_name),
      )
    end
  end
end
