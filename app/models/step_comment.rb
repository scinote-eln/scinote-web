class StepComment < Comment
  belongs_to :step, foreign_key: :associated_id

  validates :step, presence: true
end
