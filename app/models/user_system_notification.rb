# frozen_string_literal: true

class UserSystemNotification < ApplicationRecord
  belongs_to :user
  belongs_to :system_notification

  def self.mark_as_seen(notifications)
    where(system_notification_id: notifications)
      .update_all(seen_at: Time.now)
  end

  def self.mark_read(notification_id)
    notification = find_by_system_notification_id(notification_id)
    if notification && notification.read_at.nil?
      notification.update(read_at: DateTime.now)
    end
  end

  def self.modal(notification_id)
    select(:modal_title, :modal_body, "system_notifications.id").joins(:system_notification).find_by_system_notification_id(notification_id)
  end

  def self.show_on_login
      self.joins(:system_notification)
          .where("system_notifications.show_on_login = true")
          .where(:read_at => nil)
          .order("system_notifications.last_time_changed_at DESC")
          .select(:modal_title, :modal_body, "system_notifications.id")
          .first
  end 

end