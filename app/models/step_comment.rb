class StepComment < ActiveRecord::Base
  validates :comment, :step, presence: true
  validates :step_id, uniqueness: { scope: :comment_id }

  belongs_to :comment, inverse_of: :step_comment
  belongs_to :step, inverse_of: :step_comments
end
