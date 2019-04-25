# frozen_string_literal: true

class UserSystemNotification < ApplicationRecord
  belongs_to :user
  belongs_to :system_notification

  validates :system_notification, uniqueness: { scope: :user }

  scope :unseen, -> { where(seen_at: nil) }

  def self.mark_as_seen
    unseen.update_all(seen_at: Time.now)
  end

  def self.mark_as_read(notification_id)
    notification = find_by_system_notification_id(notification_id)
    notification.update(read_at: Time.now) if notification && notification.read_at.nil?
  end

  def self.show_on_login(update_read_time = false)
    # for notification check leave update_read_time empty
    notification = joins(:system_notification)
                   .where('system_notifications.show_on_login = true')
                   .order('system_notifications.created_at DESC')
                   .select(
                     :modal_title,
                     :modal_body,
                     'user_system_notifications.id',
                     :read_at,
                     :user_id,
                     :system_notification_id,
                     :created_at
                   )
                   .first
    if notification && notification.read_at.nil?
      if update_read_time
        notification.update(
          read_at: Time.now,
          seen_at: Time.now
        )
      end
      notification
    end
  end
end
