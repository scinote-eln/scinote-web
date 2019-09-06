# frozen_string_literal: true

class ResultAsset < ApplicationRecord
  validates :result, :asset, presence: true

  belongs_to :result, inverse_of: :result_asset, touch: true
  belongs_to :asset, inverse_of: :result_asset, dependent: :destroy

  def space_taken
    asset.present? ? asset.estimated_size : 0
  end
end
