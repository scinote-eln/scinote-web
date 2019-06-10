# frozen_string_literal: true

class ResultComment < Comment
  belongs_to :result, foreign_key: :associated_id, inverse_of: :result_comments, touch: true

  validates :result, presence: true
end
