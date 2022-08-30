# frozen_string_literal: true

class UserAssignment < ApplicationRecord
  before_validation -> { self.team ||= (assignable.is_a?(Team) ? assignable : assignable.team) }
  after_create :assign_shared_inventories, if: -> { assignable.is_a?(Team) }
  before_destroy :unassign_shared_inventories, if: -> { assignable.is_a?(Team) }

  belongs_to :assignable, polymorphic: true, touch: true
  belongs_to :user_role
  belongs_to :user
  belongs_to :team
  belongs_to :assigned_by, class_name: 'User', optional: true

  enum assigned: { automatically: 0, manually: 1 }, _suffix: true

  validates :user, uniqueness: { scope: %i(assignable team_id) }

  private

  def assign_shared_inventories
    assignable.repository_sharing_user_assignments
              .select('DISTINCT assignable_id, user_assignments.*')
              .find_each do |repository_sharing_user_assignment|
      new_user_assignment = repository_sharing_user_assignment.dup
      new_user_assignment.assign_attributes(user: user)
      new_user_assignment.save!
    end
  end

  def unassign_shared_inventories
    assignable.repository_sharing_user_assignments.where(user: user).find_each(&:destroy!)
  end
end
