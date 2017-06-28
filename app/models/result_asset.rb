class ResultAsset < ApplicationRecord
  validates :result, :asset, presence: true

  belongs_to :result, inverse_of: :result_asset, optional: true
  belongs_to :asset,
             inverse_of: :result_asset,
             dependent: :destroy,
             optional: true

  def space_taken
    asset.present? ? asset.estimated_size : 0
  end
end
