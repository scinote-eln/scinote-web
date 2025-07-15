# frozen_string_literal: true

class UserGroupAssignment < ApplicationRecord
  belongs_to :assignable, polymorphic: true, touch: true
  belongs_to :team
  belongs_to :user_group
  belongs_to :user_role
  belongs_to :assigned_by, class_name: 'User'

  enum :assigned, { automatically: 0, manually: 1 }, suffix: true

  validates :user_group, uniqueness: { scope: %i(assignable team_id) }

  after_destroy :call_user_group_assignment_changed_hook
  after_save :call_user_group_assignment_changed_hook

  def call_user_group_assignment_changed_hook
    assignable.__send__(:after_user_group_assignment_changed, self)
  end

  def user_group_name_with_role
    "#{user_group.name} - #{user_role.name}"
  end
end
