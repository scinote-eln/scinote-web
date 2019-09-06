# frozen_string_literal: true

class UserMyModule < ApplicationRecord
  validates :user, presence: true, uniqueness: { scope: :my_module }
  validates :my_module, presence: true

  belongs_to :user, inverse_of: :user_my_modules, touch: true
  belongs_to :assigned_by, foreign_key: 'assigned_by_id', class_name: 'User', optional: true
  belongs_to :my_module, inverse_of: :user_my_modules, touch: true
end
