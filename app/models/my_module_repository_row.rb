class MyModuleRepositoryRow < ActiveRecord::Base
  belongs_to :assigned_by, foreign_key: 'assigned_by_id', class_name: 'User'
  belongs_to :repository_row
  belongs_to :my_module

  validates :repository_row, :my_module, presence: true
  validates :repository_row, uniqueness: { scope: :my_module }
end
