class ProtocolKeyword < ActiveRecord::Base
  include InputSanitizeHelper

  auto_strip_attributes :name, nullify: false
  before_validation :sanitize_fields, on: [:create, :update]
  validates :name,
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH }
  validates :organization, presence: true

  belongs_to :organization, inverse_of: :protocol_keywords

  has_many :protocol_protocol_keywords, inverse_of: :protocol_keyword, dependent: :destroy
  has_many :protocols, through: :protocol_protocol_keywords

  private

  def sanitize_fields
    self.name = escape_input(name)
  end
end
