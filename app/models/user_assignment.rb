# frozen_string_literal: true

class UserAssignment < ApplicationRecord
  before_validation -> { self.team ||= (assignable.is_a?(Team) ? assignable : assignable.team) }

  belongs_to :assignable, polymorphic: true, touch: true
  belongs_to :user_role
  belongs_to :user
  belongs_to :team
  belongs_to :assigned_by, class_name: 'User', optional: true

  enum assigned: { automatically: 0, manually: 1 }, _suffix: true

  validates :user, uniqueness: { scope: %i(assignable team_id) }
end
