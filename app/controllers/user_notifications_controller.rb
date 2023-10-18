# frozen_string_literal: true

class UserNotificationsController < ApplicationController
  def index
    page = (params.dig(:page, :number) || 1).to_i
    notifications = load_notifications.page(page).per(Constants::INFINITE_SCROLL_LIMIT)

    render json: notifications, each_serializer: NotificationSerializer

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

end
