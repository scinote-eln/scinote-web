class UserMyModule < ApplicationRecord
  validates :user, :my_module, presence: true

  belongs_to :user, inverse_of: :user_my_modules, optional: true
  belongs_to :assigned_by,
             foreign_key: 'assigned_by_id',
             class_name: 'User',
             optional: true
  belongs_to :my_module, inverse_of: :user_my_modules,
                         touch: true,
                         optional: true
end
