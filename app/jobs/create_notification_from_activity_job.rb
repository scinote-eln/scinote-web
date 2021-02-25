# frozen_string_literal: true

class CreateNotificationFromActivityJob < ApplicationJob
  queue_as :high_priority

  def perform(activity)
    activity.generate_notification_from_activity
  end
end
