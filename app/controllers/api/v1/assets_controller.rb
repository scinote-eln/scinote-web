# frozen_string_literal: true

module Api
  module V1
    class AssetsController < BaseController
      include ::Api::V1::BlobCreation

      before_action :load_team, :load_project, :load_experiment, :load_task, :load_protocol, :load_step
      before_action :load_asset, only: :show

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

        asset = attach_blob!(@step)

        render jsonapi: asset,
               serializer: AssetSerializer,
               status: :created
      end

      private

      def asset_params
        raise TypeError unless params.require(:data).require(:type) == 'attachments'

        return params.require(:data).require(:attributes).permit(:file) if params.dig(:data, :attributes, :file)

        attr_list = %i(file_data file_type file_name signed_blob_id)
        params.require(:data).require(:attributes).permit(attr_list)
      end

      def load_asset
        @asset = @step.assets.find(params.require(:id))
        raise PermissionError.new(Asset, :read) unless can_read_protocol_in_module?(@asset.step.protocol)
      end
    end
  end
end
