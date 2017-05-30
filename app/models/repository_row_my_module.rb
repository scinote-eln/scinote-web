class RepositoryRowMyModule < ActiveRecord::Base
  validates :repository_row, :my_module, presence: true

  # One row can only be assigned once to a specific module
  validates_uniqueness_of :repository_row_id, :scope => :my_module_id

  belongs_to :assigned_by, foreign_key: 'assigned_by_id', class_name: 'User'
  belongs_to :repository_row,
    inverse_of: :repository_row_my_modules
  belongs_to :my_module,
    inverse_of: :repository_row_my_modules
end
