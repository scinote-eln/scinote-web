# frozen_string_literal: true

module Notifications
  class HandleSystemNotificationInCommunicationChannelService
    extend Service

    attr_reader :errors

    def initialize(system_notification)
      @system_notification = system_notification
      @errors = {}
    end

    def call
      @system_notification.user_system_notifications.find_each do |usn|
        user = usn.user
        AppMailer.delay.system_notification(user, @system_notification) if user.system_message_email_notification
      end

      self
    end

    def succeed?
      @errors.none?
    end
  end
end
