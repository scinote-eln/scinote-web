# frozen_string_literal: true

class UserNotificationsController < ApplicationController
  def index
    page = (params[:page] || 1).to_i
    notifications = load_notifications.page(page).per(Constants::INFINITE_SCROLL_LIMIT).without_count

    respond_to do |format|
      format.json do
        render json: {
          notifications: notification_serializer(notifications),
          next_page: notifications.next_page
        }
      end
    end

    UserNotification.where(
      notification_id: notifications.except(:select).where.not(type_of: 2).select(:id)
    ).seen_by_user(current_user)

    current_user.user_system_notifications.where(
      system_notification_id: notifications.except(:select).where(type_of: 2).select(:id)
    ).mark_as_seen
  end

  def unseen_counter
    render json: {
      unseen: load_notifications.where(checked: false).size
    }
  end

  private

  def load_notifications
    user_notifications = current_user.notifications
                                     .select(:id, :type_of, :title, :message, :created_at, 'user_notifications.checked')
    system_notifications = current_user.system_notifications
                                       .select(
                                         :id,
                                         '2 AS type_of',
                                         :title,
                                         'description AS message',
                                         :created_at,
                                         'CASE WHEN seen_at IS NULL THEN false ELSE true END AS checked'
                                       )
    notifications =
      case params[:type]
      when 'message'
        user_notifications
      when 'system'
        Notification.from("(#{system_notifications.to_sql}) AS notifications")
      else
        Notification.from(
          "((#{user_notifications.to_sql}) UNION ALL (#{system_notifications.to_sql})) AS notifications"
        )
      end
    notifications.order(created_at: :desc)
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
