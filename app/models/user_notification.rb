# frozen_string_literal: true

class UserNotification < ApplicationRecord
  include NotificationsHelper

  belongs_to :user, optional: true
  belongs_to :notification, optional: true

  after_create :send_email

  def self.last_notifications(
    user,
    last_notification_id = nil,
    per_page = Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT
  )
    last_notification_id = Constants::INFINITY if last_notification_id < 1
    Notification.joins(:user_notifications)
                .where('user_notifications.user_id = ?', user.id)
                .where('notifications.id < ?', last_notification_id)
                .order(created_at: :DESC)
                .limit(per_page)
  end

  def self.recent_notifications(user)
    Notification.joins(:user_notifications)
                .where('user_notifications.user_id = ?', user.id)
                .order(created_at: :DESC)
                .limit(Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT)
  end

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
