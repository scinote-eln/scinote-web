# frozen_string_literal: true

class UserNotificationsController < ApplicationController
  def index
    page = (params[:page] || 1).to_i
    notifications = load_notifications.page(page).per(Constants::INFINITE_SCROLL_LIMIT).without_count

    respond_to do |format|
      format.json do
        render json: {
          notifications: notifications,
          next_page: notifications.next_page
        }
      end
    end
    UserNotification.seen_by_user(current_user)
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
end
