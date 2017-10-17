class ProjectComment < Comment
  belongs_to :project, foreign_key: :associated_id,
             inverse_of: :project_comments

  validates :project, presence: true
end
