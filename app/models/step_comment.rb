# frozen_string_literal: true

class StepComment < Comment
  before_create :fill_unseen_by

  belongs_to :step, foreign_key: :associated_id, inverse_of: :step_comments

  validates :step, presence: true

  def commentable
    step
  end

  private

  def fill_unseen_by
    self.unseen_by += step.protocol.my_module.experiment.project.users.where.not(id: user.id).pluck(:id)
  end
end
