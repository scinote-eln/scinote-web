class ProtocolKeyword < ActiveRecord::Base
  validates :name, presence: true, length: { maximum: 50 }
  validates :organization, presence: true

  belongs_to :organization, inverse_of: :protocol_keywords

  has_many :protocol_protocol_keywords, inverse_of: :protocol_keyword, dependent: :destroy
  has_many :protocols, through: :protocol_protocol_keywords
end