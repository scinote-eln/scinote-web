class ProjectComment < Comment
  belongs_to :project, foreign_key: :associated_id

  validates :project, presence: true
end
