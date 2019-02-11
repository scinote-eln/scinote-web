# frozen_string_literal: true

class SystemNotificationsController < ApplicationController
  before_action :prepare_notifications, only: :index

  def index
    respond_to do |format|
      format.json do
        render json: {
          more_url: @system_notifications.fetch(:more_notifications_url),
          html: render_to_string(
            partial: 'list.html.erb', locals: @system_notifications
          )
        }
      end
      format.html
    end
  end

  # Update seen_at parameter for system notifications
  def mark_as_seen
    notifications = JSON.parse(params[:notifications])
    current_user.user_system_notifications.mark_as_seen(notifications)
    render json: { result: 'ok' }
  rescue StandardError
    render json: { result: 'failed' }
  end

  private

  def prepare_notifications
    page = (params[:page] || 1).to_i
    system_notifications = SystemNotification.last_notifications(current_user, params[:search_queue])
                                             .page(page).per(Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT)
    unless system_notifications.blank? || system_notifications.last_page?
      more_url = url_for(
        system_notifications_url(
          format: :json,
          page: page + 1
        )
      )
    end
    @system_notifications = {
      notifications: system_notifications,
      more_notifications_url: more_url || nil
    }
  end
end
