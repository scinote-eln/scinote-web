# frozen_string_literal: true

class StepAsset < ApplicationRecord
  include ObservableModel

  belongs_to :step, inverse_of: :step_assets, touch: true
  belongs_to :asset, inverse_of: :step_asset, dependent: :destroy

  private

  # Override for ObservableModel
  def changed_by
    step&.last_modified_by
  end
end
