class ResultText < ActiveRecord::Base
  validates :text, presence: true
  validates :result, presence: true

  belongs_to :result, inverse_of: :result_text

end
