# frozen_string_literal: true

class UserAssignment < ApplicationRecord
  belongs_to :assignable, polymorphic: true
  belongs_to :user_role
  belongs_to :user
  belongs_to :assigned_by, foreign_key: 'assigned_by_id', class_name: 'User', optional: true
end
