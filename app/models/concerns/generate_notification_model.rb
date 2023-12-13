# frozen_string_literal: true

module GenerateNotificationModel
  extend ActiveSupport::Concern
  include GlobalActivitiesHelper

  included do
    after_create :generate_notification
  end

  def generate_notification_from_activity
    params = { activity_id: id, type: "#{type_of}_activity".to_sym }
    ActivityNotification.send_notifications(params, later: true)
  end

  protected

  def notifiable?
    NotificationExtends::NOTIFICATIONS_TYPES.key?("#{type_of}_activity".to_sym)
  end

  private

  def generate_notification
    CreateNotificationFromActivityJob.perform_later(self) if notifiable?
  end
end
