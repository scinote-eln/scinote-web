class UserMyModule < ActiveRecord::Base
  validates :user, :my_module, presence: true

  belongs_to :user, inverse_of: :user_my_modules
  belongs_to :assigned_by, foreign_key: 'assigned_by_id', class_name: 'User'
  belongs_to :my_module, inverse_of: :user_my_modules
end
