# frozen_string_literal: true

module Api
  module V1
    class ResultAssetSerializer < ActiveModel::Serializer
      type :result_assets
      attributes :asset_id
    end
  end
end
