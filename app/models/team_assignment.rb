# frozen_string_literal: true

class TeamAssignment < ApplicationRecord
  belongs_to :assignable, polymorphic: true, touch: true
  belongs_to :team
  belongs_to :user_role
  belongs_to :assigned_by, class_name: 'User', optional: true
  has_many :users, through: :team

  enum :assigned, { automatically: 0, manually: 1 }, suffix: true

  scope :as_owners, -> { where(user_role: UserRole.find_predefined_owner_role) }
  scope :as_normal_users, -> { where(user_role: UserRole.find_predefined_normal_user_role) }
  scope :as_viewers, -> { where(user_role: UserRole.find_predefined_viewer_role) }

  validates :team, uniqueness: { scope: :assignable }

  after_destroy :call_team_assignment_changed_hook
  after_save :call_team_assignment_changed_hook

  def call_team_assignment_changed_hook
    assignable.__send__(:after_team_assignment_changed, self)
  end
end
