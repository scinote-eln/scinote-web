# frozen_string_literal: true

module Api
  module V2
    module ResultElements
      class AssetsController < ::Api::V2::BaseController
        before_action :load_team, :load_project, :load_experiment, :load_task, :load_result
        before_action :check_manage_permission, only: %i(create destroy)
        before_action :load_asset, only: %i(show destroy)
        before_action :check_upload_type, only: :create

        def index
          result_assets =
            timestamps_filter(@result.assets).page(params.dig(:page, :number))
                                             .per(params.dig(:page, :size))

          render jsonapi: result_assets, each_serializer: Api::V2::AssetSerializer
        end

        def show
          render jsonapi: @asset, serializer: Api::V2::AssetSerializer
        end

        def create
          asset = if @form_multipart_upload
                    @result.assets.new(asset_params.merge({ team_id: @team.id }))
                  else
                    blob = ActiveStorage::Blob.create_and_upload!(
                      io: StringIO.new(Base64.decode64(asset_params[:file_data])),
                      filename: asset_params[:file_name],
                      content_type: asset_params[:file_type]
                    )
                    @result.assets.new(file: blob, team: @team)
                  end

          asset.save!(context: :on_api_upload)
          asset.post_process_file

          render jsonapi: asset,
                 serializer: Api::V2::AssetSerializer,
                 status: :created
        end

        def destroy
          @asset.destroy!
          render body: nil
        end

        private

        def asset_params
          raise TypeError unless params.require(:data).require(:type) == 'attachments'

          return params.require(:data).require(:attributes).permit(:file) if @form_multipart_upload

          attr_list = %i(file_data file_type file_name)
          params.require(:data).require(:attributes).require(attr_list)
          params.require(:data).require(:attributes).permit(attr_list)
        end

        def load_asset
          @asset = @result.assets.find(params.require(:id))
          raise PermissionError.new(Result, :read) unless can_read_result?(@result)
        end

        def check_upload_type
          @form_multipart_upload = true if params.dig(:data, :attributes, :file)
        end

        def check_manage_permission
          raise PermissionError.new(Result, :manage) unless can_manage_result?(@result)
        end
      end
    end
  end
end
