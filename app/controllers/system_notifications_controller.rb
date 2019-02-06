# frozen_string_literal: true

class SystemNotificationsController < ApplicationController
  def index
    @system_notifications = prepare_notifications
    respond_to do |format|
      format.json do
        render json: {
          more_url: prepare_notifications.fetch(:more_notifications_url),
          html: render_to_string(
            partial: 'list.html.erb', locals: @system_notifications
          )
        }
      end
      format.html
    end
  end
  
  # Update seen_at parameter for system notifications
  def mark
    notifications = JSON.parse(params[:notifications])
    current_user.user_system_notifications.mark(notifications)
    render json: { result: 'ok' }
  rescue StandardError
    render json: { result: 'failed' }
  end

  private

  def prepare_notifications
    page = (params[:page] || 1).to_i
    system_notifications = SystemNotification.last_notifications(current_user, params[:q])
                                             .page(page).per(Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT)
    unless system_notifications.blank? || system_notifications.last_page?
      more_url = url_for(
        system_notifications_url(
          format: :json,
           page: page + 1,
           last_notification: system_notifications.last.id
        )
      )
    end
    {
      notifications: system_notifications,
      more_notifications_url: more_url,
      page: page
    }
  end
end
