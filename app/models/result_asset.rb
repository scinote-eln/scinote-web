# frozen_string_literal: true

class ResultAsset < ApplicationRecord
  belongs_to :result, inverse_of: :result_assets, touch: true
  belongs_to :asset, inverse_of: :result_asset, dependent: :destroy

  def space_taken
    asset.present? ? asset.estimated_size : 0
  end
end
