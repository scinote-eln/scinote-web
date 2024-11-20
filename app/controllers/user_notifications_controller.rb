# frozen_string_literal: true

class UserNotificationsController < ApplicationController
  prepend_before_action -> { request.env['devise.skip_trackable'] = true }, only: :unseen_counter

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

  def unseen_counter
    render json: {
      unseen: load_notifications.where(read_at: nil).size
    }
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
