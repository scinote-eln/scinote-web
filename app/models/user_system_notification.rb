# frozen_string_literal: true

class UserSystemNotification < ApplicationRecord
  belongs_to :user
  belongs_to :system_notification

  scope :unseen, -> { where(seen_at: nil) }

  def self.mark_as_seen(notifications_id)
    where(system_notification_id: notifications_id)
      .update_all(seen_at: Time.now)
  end

  def self.mark_as_read(notification_id)
    notification = find_by_system_notification_id(notification_id)
    if notification && notification.read_at.nil?
      notification.update(read_at: Time.now)
    end
  end

  def self.modal(notification_id)
    select(:modal_title, :modal_body, 'system_notifications.id')
      .joins(:system_notification)
      .find_by_system_notification_id(notification_id)
  end

  def self.show_on_login(update_read_time = false)
    # for notification check leave update_read_time empty
    notification = joins(:system_notification)
                   .where('system_notifications.show_on_login = true')
                   .order('system_notifications.last_time_changed_at DESC')
                   .select(
                     :modal_title,
                     :modal_body,
                     'user_system_notifications.id',
                     :read_at,
                     :user_id,
                     :system_notification_id
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
