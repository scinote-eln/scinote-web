# frozen_string_literal: true

class UserSystemNotification < ApplicationRecord
  belongs_to :user
  belongs_to :system_notification

  def self.mark(notifications=[])
  	self.where(:system_notification_id => notifications).update_all(:seen_at => DateTime.now)
  end
end
