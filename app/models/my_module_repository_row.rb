class MyModuleRepositoryRow < ApplicationRecord
  belongs_to :assigned_by,
             foreign_key: 'assigned_by_id',
             class_name: 'User',
             optional: true
  belongs_to :repository_row,
             optional: true,
             inverse_of: :my_module_repository_rows
  belongs_to :my_module, optional: true, inverse_of: :my_module_repository_rows

  validates :repository_row, :my_module, presence: true
  validates :repository_row, uniqueness: { scope: :my_module }
end
