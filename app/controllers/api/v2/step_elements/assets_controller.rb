# frozen_string_literal: true

module Api
  module V2
    module StepElements
      class AssetsController < ::Api::V1::AssetsController
        def index
          attachments =
            timestamps_filter(@step.assets).page(params.dig(:page, :number))
                                           .per(params.dig(:page, :size))

          render jsonapi: attachments, each_serializer: Api::V2::AssetSerializer
        end

        def show
          render jsonapi: @asset, serializer: Api::V2::AssetSerializer
        end

        def create
          raise PermissionError.new(Asset, :create) unless can_manage_protocol_in_module?(@protocol)

          if @form_multipart_upload
            asset = @step.assets.new(asset_params.merge({ team_id: @team.id }))
          else
            blob = ActiveStorage::Blob.create_and_upload!(
              io: StringIO.new(Base64.decode64(asset_params[:file_data])),
              filename: asset_params[:file_name],
              content_type: asset_params[:file_type]
            )
            asset = @step.assets.new(file: blob, team: @team)
          end

          asset.save!(context: :on_api_upload)
          asset.post_process_file

          render jsonapi: asset,
                 serializer: Api::V2::AssetSerializer,
                 status: :created
        end
      end
    end
  end
end
