# frozen_string_literal: true

class Notification < ApplicationRecord
  has_many :user_notifications, inverse_of: :notification, dependent: :destroy
  has_many :users, through: :user_notifications
  belongs_to :generator_user, class_name: 'User', optional: true

  enum type_of: Extends::NOTIFICATIONS_TYPES

  def create_user_notification(user)
    return if user == generator_user
    return unless can_send_to_user?(user)
    return unless user.enabled_notifications_for?(type_of.to_sym, :web)

    user_notifications.create!(user: user)
  end

  private

  def can_send_to_user?(_user)
    true # overridable send permission method
  end
end
