class ResultText < ActiveRecord::Base
  include InputSanitizeHelper

  auto_strip_attributes :text, nullify: false
  before_validation :sanitize_fields, on: [:create, :update]
  validates :text,
            presence: true,
            length: { maximum: Constants::RICH_TEXT_MAX_LENGTH }
  validates :result, presence: true

  belongs_to :result, inverse_of: :result_text

  private

  def sanitize_fields
    self.text = sanitize_input(text)
  end
end
