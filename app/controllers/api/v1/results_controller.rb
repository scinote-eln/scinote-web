# frozen_string_literal: true

module Api
  module V1
    class ResultsController < BaseController
      before_action :load_team, :load_project, :load_experiment, :load_task
      before_action :load_result, only: %i(show update)
      before_action :check_manage_permissions, only: %i(create update)

      def index
        results = @task.results
                       .page(params.dig(:page, :number))
                       .per(params.dig(:page, :size))
        render jsonapi: results, each_serializer: ResultSerializer,
                                 include: %i(text table file)
      end

      def create
        create_text_result if result_text_params.present?

        create_file_result if !@result && result_file_params.present?

        render jsonapi: @result,
               serializer: ResultSerializer,
               include: %i(text table file),
               status: :created
      end

      def update
        @result.attributes = result_params

        update_file_result if result_file_params.present? && @result.is_asset
        update_text_result if result_text_params.present? && @result.is_text

        if (@result.changed? && @result.save!) || @asset_result_updated
          render jsonapi: @result,
                 serializer: ResultSerializer,
                 include: %i(text table file),
                 status: :ok
        else
          render body: nil, status: :no_content
        end
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
        raise PermissionError.new(MyModule, :manage) unless can_manage_module?(@task)
      end

      def create_text_result
        # rubocop:disable Metrics/BlockLength:
        Result.transaction do
          @result = Result.create!(
            user: current_user,
            my_module: @task,
            name: result_params[:name],
            last_modified_by: current_user
          )

          result_text = ResultText.create!(
            result: @result,
            text: convert_old_tiny_mce_format(result_text_params[:text])
          )

          if tiny_mce_asset_params.present?
            tiny_mce_asset_params.each do |t|
              image_params = t[:attributes]
              token = image_params[:file_token]
              unless result_text.text["data-mce-token=\"#{token}\""]
                raise ActiveRecord::RecordInvalid,
                      I18n.t('api.core.errors.result_wrong_tinymce.detail')
              end
              tiny_image = TinyMceAsset.create!(
                team: @team,
                object: result_text,
                saved: true
              )
              tiny_image.image.attach(
                io: StringIO.new(Base64.decode64(image_params[:file_data].split(',')[1])),
                filename: image_params[:file_name]
              )
              result_text.text.sub!("data-mce-token=\"#{token}\"", "data-mce-token=\"#{Base62.encode(tiny_image.id)}\"")
            end
            result_text.save!
          end
        end
        # rubocop:enable Metrics/BlockLength:
      end

      def update_text_result
        raise NotImplementedError, 'update_text_result should be implemented!'
      end

      def create_file_result
        Result.transaction do
          @result = @task.results.create!(result_params.merge(user_id: current_user.id))
          asset = Asset.create!(result_file_params)
          ResultAsset.create!(asset: asset, result: @result)
        end
      end

      def update_file_result
        old_checksum, new_checksum = nil
        Result.transaction do
          old_checksum = @result.asset.file.blob.checksum
          @result.asset.file.attach(result_file_params[:file])
          new_checksum = @result.asset.file.blob.checksum
        end
        @asset_result_updated = old_checksum != new_checksum
      end

      def result_params
        raise TypeError unless params.require(:data).require(:type) == 'results'

        params.require(:data).require(:attributes).require(:name)
        params.permit(data: { attributes: :name })[:data][:attributes]
      end

      # Partially implement sideposting draft
      # https://github.com/json-api/json-api/pull/1197
      def result_text_params
        prms = params[:included]&.select { |el| el[:type] == 'result_texts' }&.first
        return nil unless prms

        prms.require(:attributes).require(:text)
        prms.dig(:attributes).permit(:text)
      end

      def result_file_params
        prms = params[:included]&.select { |el| el[:type] == 'result_files' }&.first
        return nil unless prms

        prms.require(:attributes).require(:file)
        prms.dig(:attributes).permit(:file)
      end

      def tiny_mce_asset_params
        prms = params[:included]&.select { |el| el[:type] == 'tiny_mce_assets' }
        prms.each do |p|
          p.require(:attributes).require(%i(file_data file_name file_token))
        end
        file_tokens = prms.map { |p| p[:attributes][:file_token] }
        result_text_params[:text].scan(
          /data-mce-token="(\w+)"/
        ).flatten.each do |token|
          unless file_tokens.include?(token)
            raise ActiveRecord::RecordInvalid,
                  I18n.t('api.core.errors.result_missing_tinymce.detail')
          end
        end
        prms
      end

      def convert_old_tiny_mce_format(text)
        text.scan(/\[~tiny_mce_id:(\w+)\]/).flatten.each do |token|
          old_format = /\[~tiny_mce_id:#{token}\]/
          new_format = "<img src=\"\" class=\"img-responsive\" data-mce-token=\"#{token}\"/>"
          text.sub!(old_format, new_format)
        end
        text
      end
    end
  end
end
