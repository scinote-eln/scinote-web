class ProjectComment < ActiveRecord::Base
  validates :comment, :project, presence: true
  validates :project_id, uniqueness: { scope: :comment_id }

  belongs_to :comment, inverse_of: :project_comment
  belongs_to :project, inverse_of: :project_comments
end
