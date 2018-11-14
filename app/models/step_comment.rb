class StepComment < Comment
  belongs_to :step,
             foreign_key: :associated_id,
             inverse_of: :step_comments,
             touch: true,
             optional: true

  validates :step, presence: true
end
