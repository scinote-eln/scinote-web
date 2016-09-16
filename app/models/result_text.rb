class ResultText < ActiveRecord::Base
  validates :text, presence: true, length: { maximum: TEXT_MAX_LENGTH }
  validates :result, presence: true

  belongs_to :result, inverse_of: :result_text
end
