# frozen_string_literal: true

class TaskComment < Comment
  before_create :fill_unseen_by

  belongs_to :my_module, foreign_key: :associated_id, inverse_of: :task_comments

  validates :my_module, presence: true

  def commentable
    my_module
  end

  private

  def fill_unseen_by
    self.unseen_by += my_module.experiment.project.users.where.not(id: user.id).pluck(:id)
  end
end
