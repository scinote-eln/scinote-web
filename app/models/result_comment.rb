class ResultComment < Comment
  belongs_to :result, foreign_key: :associated_id

  validates :result, presence: true
end
