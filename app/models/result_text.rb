class ResultText < ApplicationRecord
  auto_strip_attributes :text, nullify: false
  validates :text,
            presence: true,
            length: { maximum: Constants::RICH_TEXT_MAX_LENGTH }
  validates :result, presence: true
  belongs_to :result, inverse_of: :result_text, optional: true
  has_many :tiny_mce_assets, inverse_of: :result_text, dependent: :destroy
end
