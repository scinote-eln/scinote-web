# frozen_string_literal: true

class ResultAsset < ApplicationRecord
  belongs_to :result, inverse_of: :result_assets, touch: true, optional: true
  belongs_to :result_template, inverse_of: :result_assets, optional: true
  belongs_to :asset, inverse_of: :result_asset, dependent: :destroy

  validates :result_id, presence: true, unless: :result_template_id
  validates :result_template_id, presence: true, unless: :result_id

  def space_taken
    asset.present? ? asset.estimated_size : 0
  end

  def result_or_template
    result_template || result
  end
end
