class StepComment < Comment
  belongs_to :step,
             foreign_key: :associated_id,
             inverse_of: :step_comments,
             optional: true

  validates :step, presence: true
end
