# frozen_string_literal: true

module Api
  module V2
    module ResultElements
      class TextsController < BaseController
        before_action :load_team, :load_project, :load_experiment, :load_task, :load_result
        before_action only: %i(show update destroy) do
          load_result_text(:id)
        end
        before_action :check_manage_permission, only: %i(create update destroy)

        def index
          result_texts = timestamps_filter(@result.result_texts).page(params.dig(:page, :number))
                                                                .per(params.dig(:page, :size))

          render jsonapi: result_texts, each_serializer: ResultTextSerializer
        end

        def show
          render jsonapi: @result_text, serializer: ResultTextSerializer
        end

        def create
          result_text = @result.result_texts.new(result_text_params)

          @result.with_lock do
            @result.result_orderable_elements.create!(
              position: @result.result_orderable_elements.size,
              orderable: result_text
            )

            result_text.save!
          end

          render jsonapi: result_text, serializer: ResultTextSerializer, status: :created
        end

        def update
          @result_text.assign_attributes(result_text_params)

          if @result_text.changed? && @result_text.save!
            render jsonapi: @result_text, serializer: ResultTextSerializer, status: :ok
          else
            render body: nil, status: :no_content
          end
        end

        def destroy
          @result_text.destroy!
          render body: nil
        end

        private

        def check_manage_permission
          raise PermissionError.new(Result, :manage) unless can_manage_result?(@result)
        end

        def result_text_params
          raise TypeError unless params.require(:data).require(:type) == 'result_texts'

          params.require(:data).require(:attributes).permit(:text, :name)
        end
      end
    end
  end
end
