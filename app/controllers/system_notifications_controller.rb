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

  def show
    render json: current_user.system_notifications.modals
                             .find_by_id(params[:id]) || {}
  end

  # Update seen_at parameter for system notifications
  def mark_as_seen
    current_user.user_system_notifications.mark_as_seen
    render json: { result: 'ok' }
  rescue StandardError
    render json: { result: 'failed' }
  end

  # Update read_at parameter for system notifications
  def mark_as_read
    current_user.user_system_notifications.mark_as_read(params[:id])
    render json: { result: 'ok' }
  rescue StandardError
    render json: { result: 'failed' }
  end

  def unseen_counter
    render json: {
      notificationNmber: current_user.user_system_notifications.unseen.count
    }
  end

  private

  def prepare_notifications
    page = (params[:page] || 1).to_i
    query = params[:search_queue]
    per_page = Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT
    notifications = SystemNotification.last_notifications(current_user, query)
                                      .page(page)
                                      .per(per_page)

    unless notifications.blank? || notifications.last_page?
      more_url = url_for(
        system_notifications_url(
          format: :json,
          page: page + 1,
          search_queue: query
        )
      )
    end
    @system_notifications = {
      notifications: notifications,
      more_notifications_url: more_url
    }
  end
end
