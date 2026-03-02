# frozen_string_literal: true

class UserNotificationsController < ApplicationController
  after_action -> { Notification.broadcast_unseen_count_to(current_user) },
               only: %i(mark_all_read toggle_read)

  def index
    page = (params.dig(:page, :number) || 1).to_i
    notifications = load_notifications

    case params[:tab]
    when 'read'
      notifications = notifications.where.not(read_at: nil)
    when 'unread'
      notifications = notifications.where(read_at: nil)
    end

    notifications = notifications.page(page).per(Constants::INFINITE_SCROLL_LIMIT)

    render json: notifications, each_serializer: NotificationSerializer
  end

  def mark_all_read
    load_notifications.mark_as_read!
    render json: { success: true }
  end

  def toggle_read
    notification = current_user.notifications.find(params[:id])
    notification.update(read_at: (params[:mark_as_read] ? DateTime.now : nil))
    render json: notification, serializer: NotificationSerializer
  end

  private

  def load_notifications
    current_user.notifications
                .in_app
                .order(created_at: :desc)
  end
end
