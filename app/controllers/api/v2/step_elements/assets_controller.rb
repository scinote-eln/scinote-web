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

          asset = attach_blob!(@step)

          render jsonapi: asset,
                 serializer: Api::V2::AssetSerializer,
                 status: :created
        end
      end
    end
  end
end
