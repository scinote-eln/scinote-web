class ResultComment < Comment
  belongs_to :result, foreign_key: :associated_id, inverse_of: :result_comments

  validates :result, presence: true
end
