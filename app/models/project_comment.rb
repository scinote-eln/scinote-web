# frozen_string_literal: true

class ProjectComment < Comment
  before_create :fill_unseen_by

  belongs_to :project, foreign_key: :associated_id, inverse_of: :project_comments, touch: true

  validates :project, presence: true

  def commentable
    project
  end

  private

  def fill_unseen_by
    self.unseen_by += project.users.where.not(id: user.id).pluck(:id)
  end
end
