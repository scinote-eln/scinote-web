# frozen_string_literal: true

class StepAsset < ApplicationRecord
  belongs_to :step, inverse_of: :step_assets, touch: true
  belongs_to :asset, inverse_of: :step_asset, dependent: :destroy
end
