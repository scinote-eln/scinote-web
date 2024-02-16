# frozen_string_literal: true

module Api
  module V1
    class AssetsController < BaseController
      before_action :load_team, :load_project, :load_experiment, :load_task, :load_protocol, :load_step
      before_action :load_asset, only: :show
      before_action :check_upload_type, only: :create

      def index
        attachments =
          timestamps_filter(@step.assets).page(params.dig(:page, :number))
                                         .per(params.dig(:page, :size))

        render jsonapi: attachments, each_serializer: AssetSerializer
      end

      def show
        render jsonapi: @asset, serializer: AssetSerializer
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
               serializer: AssetSerializer,
               status: :created
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
        @asset = @step.assets.find(params.require(:id))
        raise PermissionError.new(Asset, :read) unless can_read_protocol_in_module?(@asset.step.protocol)
      end

      def check_upload_type
        @form_multipart_upload = true if params.dig(:data, :attributes, :file)
      end
    end
  end
end
