class TaskComment < Comment
  belongs_to :my_module, foreign_key: :associated_id

  validates :my_module, presence: true
end
