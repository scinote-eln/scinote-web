# frozen_string_literal: true

module Api
  module V1
    class ResultsController < BaseController
      include TinyMceHelper

      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :load_task
      before_action :load_result, only: %i(show)
      before_action :check_manage_permissions, only: %i(create)

      def index
        results = @task.results
                       .page(params.dig(:page, :number))
                       .per(params.dig(:page, :size))
        render jsonapi: results, each_serializer: ResultSerializer,
                                 include: %i(text table file)
      end

      def create
        create_text_result if result_text_params.present?
        render jsonapi: @result,
               serializer: ResultSerializer,
               include: %i(text table file),
               status: :created
      end

      def show
        render jsonapi: @result, serializer: ResultSerializer,
                                 include: %i(text table file)
      end

      private

      def load_result
        @result = @task.results.find(params.require(:id))
      end

      def check_manage_permissions
        unless can_manage_module?(@task)
          raise PermissionError.new(MyModule, :manage)
        end
      end

      def create_text_result
        result_text = ResultText.new(text: result_text_params[:text])
        result_text.transaction do
          if tiny_mce_asset_params.present?
            tiny_mce_asset_params.each do |t|
              image_params = t[:attributes]
              token = image_params[:file_token]
              unless result_text.text["[~tiny_mce_id:#{token}]"]
                raise ActiveRecord::RecordInvalid,
                      I18n.t('api.core.errors.result_wrong_tinymce.detail')
              end
              image = Paperclip.io_adapters.for(image_params[:file_data])
              image.original_filename = image_params[:file_name]
              tiny_img = TinyMceAsset.create!(image: image, team: @team)
              result_text.text.sub!("[~tiny_mce_id:#{token}]",
                                    "[~tiny_mce_id:#{tiny_img.id}]")
            end
          end
          @result = Result.new(user: current_user,
                               my_module: @task,
                               name: result_params[:name],
                               result_text: result_text,
                               last_modified_by: current_user)
          @result.save! && result_text.save!
          link_tiny_mce_assets(result_text.text, result_text)
        end
      end

      def result_params
        raise TypeError unless params.require(:data).require(:type) == 'results'
        params.require(:data).require(:attributes).require(:name)
        params.permit(data: { attributes: :name })[:data][:attributes]
      end

      # Partially implement sideposting draft
      # https://github.com/json-api/json-api/pull/1197
      def result_text_params
        prms =
          params[:included]&.select { |el| el[:type] == 'result_texts' }&.first
        prms.require(:attributes).require(:text)
        prms[:attributes]
      end

      def tiny_mce_asset_params
        prms = params[:included]&.select { |el| el[:type] == 'tiny_mce_assets' }
        prms.each do |p|
          p.require(:attributes).require(%i(file_data file_name file_token))
        end
        file_tokens = prms.map { |p| p[:attributes][:file_token] }
        result_text_params[:text].scan(
          /\[~tiny_mce_id:(\w+)\]/
        ).flatten.each do |token|
          unless file_tokens.include?(token)
            raise ActiveRecord::RecordInvalid,
                  I18n.t('api.core.errors.result_missing_tinymce.detail')
          end
        end
        prms
      end
    end
  end
end
