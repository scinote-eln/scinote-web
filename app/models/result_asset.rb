# frozen_string_literal: true

class ResultAsset < ApplicationRecord
  include ObservableModel

  belongs_to :result, inverse_of: :result_assets, touch: true, class_name: 'ResultBase'
  belongs_to :asset, inverse_of: :result_asset, dependent: :destroy

  def space_taken
    asset.present? ? asset.estimated_size : 0
  end

  private

  # Override for ObservableModel
  def changed_by
    result&.last_modified_by
  end
end
