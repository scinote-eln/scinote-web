# frozen_string_literal: true

class AssetTextDatum < ApplicationRecord
  include SearchableModel

  validates :asset, uniqueness: true
  belongs_to :asset, inverse_of: :asset_text_datum
end
