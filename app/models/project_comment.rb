class ProjectComment < Comment
  belongs_to :project,
             foreign_key: :associated_id,
             inverse_of: :project_comments,
             touch: true,
             optional: true

  validates :project, presence: true
end
