class TaskComment < Comment
  belongs_to :my_module,
             foreign_key: :associated_id,
             inverse_of: :task_comments,
             optional: true

  validates :my_module, presence: true
end
