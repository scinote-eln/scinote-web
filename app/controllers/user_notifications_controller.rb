# frozen_string_literal: true

class UserNotificationsController < ApplicationController
  def index
    page = (params[:page] || 1).to_i
    notifications = load_notifications.page(page).per(Constants::INFINITE_SCROLL_LIMIT).without_count

    render json: {
      notifications: notification_serializer(notifications),
      next_page: notifications.next_page
    }

    notifications.mark_as_read!
  end

  def unseen_counter
    render json: {
      unseen: load_notifications.where(read_at: nil).size
    }
  end

  private

  def load_notifications
    current_user.notifications
                .order(created_at: :desc)
  end

  def notification_serializer(notifications)
    notifications.map do |notification|
      {
        id: notification.id,
        type_of: notification.type,
        title: notification.to_notification.title,
        message: notification.to_notification.message,
        created_at: I18n.l(notification.created_at, format: :full),
        today: notification.created_at.today?,
        checked: notification.read_at.present?
      }
    end
  end
end
