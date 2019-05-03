class StepAsset < ApplicationRecord
  validates :step, :asset, presence: true

  belongs_to :step,
             inverse_of: :step_assets,
             touch: true,
             optional: true
  belongs_to :asset,
             inverse_of: :step_asset,
             dependent: :destroy,
             optional: true
end
