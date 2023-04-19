# frozen_string_literal: true

class UserNotification < ApplicationRecord
  include NotificationsHelper

  belongs_to :user, optional: true
  belongs_to :notification, optional: true

  after_create :send_email

  def self.unseen_notification_count(user)
    where('user_id = ? AND checked = false', user.id).count
  end

  def self.seen_by_user(user)
    where(user: user).where(checked: false).update_all(checked: true)
  end

  def send_email
    send_email_notification(user, notification) if user.enabled_notifications_for?(notification.type_of.to_sym, :email)
  end
end
