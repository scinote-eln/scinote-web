# frozen_string_literal: true

class NotificationCleanupJob < ApplicationJob
  def perform
    NewRelic::Agent.ignore_transaction
    Notification.where('created_at < ?', 3.months.ago).delete_all
  end
end
