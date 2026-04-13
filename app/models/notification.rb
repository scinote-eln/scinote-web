# frozen_string_literal: true

class Notification < ApplicationRecord
  include Noticed::Model

  belongs_to :recipient, polymorphic: true

  scope :in_app, lambda {
    where.not("notifications.params ? 'hide_in_app' AND notifications.params->'hide_in_app' = 'true'")
  }

  after_create -> { Notification.broadcast_unseen_count_to(recipient) unless params[:hide_in_app] }

  def self.broadcast_unseen_count_to(user)
    UserNotificationsChannel.broadcast_to(user, unseen_count: user.notifications.in_app.where(read_at: nil).count)
  end

  private

  def can_send_to_user?(_user)
    true # overridable send permission method
  end
end
