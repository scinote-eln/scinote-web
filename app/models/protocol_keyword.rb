class ProtocolKeyword < ApplicationRecord
  auto_strip_attributes :name, nullify: false
  validates :name,
            uniqueness: { scope: :team },
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH }
  validates :team, presence: true

  belongs_to :team, inverse_of: :protocol_keywords

  has_many :protocol_protocol_keywords,
           inverse_of: :protocol_keyword,
           dependent: :destroy
  has_many :protocols, through: :protocol_protocol_keywords
end
