# frozen_string_literal: true

class StepComment < Comment
  include ObservableModel

  before_create :fill_unseen_by
  after_create :run_observers

  belongs_to :step, foreign_key: :associated_id, inverse_of: :step_comments

  validates :step, presence: true

  def commentable
    step
  end

  private

  def fill_unseen_by
    self.unseen_by += step.protocol.my_module.experiment.project.users.where.not(id: user.id).pluck(:id)
  end

  def run_observers
    AutomationObservers::ProtocolContentChangedAutomationObserver.new(step, last_modified_by || user).call
  end
end
