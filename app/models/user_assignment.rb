# frozen_string_literal: true

class UserAssignment < ApplicationRecord
  belongs_to :assignable, polymorphic: true
  belongs_to :user_role
  belongs_to :user
  belongs_to :assigned_by, class_name: 'User', optional: true

  enum assigned: { automatically: 0, manually: 1 }, _suffix: true

  after_destroy :touch_assignable
  after_save :touch_assignable

  private

  def touch_assignable
    # This busts the cache of cached assigned user lists.
    # Using .update_column instead of .touch, to avoid triggering an audit trail callback
    assignable.update_column(:updated_at, Time.zone.now)
  end
end
