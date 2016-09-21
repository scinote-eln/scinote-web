class ProtocolKeyword < ActiveRecord::Base
  auto_strip_attributes :name, nullify: false
  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :organization, presence: true

  belongs_to :organization, inverse_of: :protocol_keywords

  has_many :protocol_protocol_keywords, inverse_of: :protocol_keyword, dependent: :destroy
  has_many :protocols, through: :protocol_protocol_keywords
end