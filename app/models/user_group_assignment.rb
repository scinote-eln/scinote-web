# frozen_string_literal: true

class UserGroupAssignment < ApplicationRecord
  belongs_to :assignable, polymorphic: true, touch: true
  belongs_to :team
  belongs_to :user_group
  belongs_to :user_role
  belongs_to :created_by, class_name: 'User'
  belongs_to :last_modified_by, class_name: 'User'

  enum assigned: { automatically: 0, manually: 1 }, _suffix: true

  validates :user_group, uniqueness: { scope: %i(assignable team_id) }
end
