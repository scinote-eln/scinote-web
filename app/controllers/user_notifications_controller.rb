# frozen_string_literal: true

class UserNotificationsController < ApplicationController
  def index
    page = (params[:page] || 1).to_i
    notifications = load_notifications.page(page).per(Constants::INFINITE_SCROLL_LIMIT).without_count

    render json: {
      notifications: notification_serializer(notifications),
      next_page: notifications.next_page
    }

    UserNotification.where(
      notification_id: notifications.except(:select).where.not(type_of: 2).select(:id)
    ).seen_by_user(current_user)
  end

  def unseen_counter
    render json: {
      unseen: load_notifications.where('user_notifications.checked = ?', false).size
    }
  end

  private

  def load_notifications
    current_user.notifications
                .select(:id, :type_of, :title, :message, :created_at, 'user_notifications.checked')
                .order(created_at: :desc)
  end

  def notification_serializer(notifications)
    notifications.map do |notification|
      {
        id: notification.id,
        type_of: notification.type_of,
        title: notification.title,
        message: notification.message,
        created_at: I18n.l(notification.created_at, format: :full),
        today: notification.created_at.today?,
        checked: notification.checked
      }
    end
  end
end
