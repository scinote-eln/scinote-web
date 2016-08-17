class StepAsset < ActiveRecord::Base
  validates :step, :asset, presence: true

  belongs_to :step, inverse_of: :step_assets
  belongs_to :asset, inverse_of: :step_asset, :dependent => :destroy
end
