class UserNotificationsController < ApplicationController
  layout 'main'

  def index
    @last_notification_id = params[:from].to_i || 0
    @per_page = 5

    @notifications =
      UserNotification.last_notifications(@current_user,
                                          @last_notification_id,
                                          @per_page + 1)

    @more_notifications_url = ""

    @overflown = @notifications.length > @per_page

    @notifications = UserNotification
      .last_notifications(@current_user, @last_notification_id, @per_page)

    if @notifications.count > 0
      @more_notifications_url = url_for(
        controller: 'user_notifications',
        action: 'index',
        format: :json,
        from: @notifications.last.id)
    end

    respond_to do |format|
      format.html
      format.json {
        render :json => {
          :per_page => @per_page,
          :results_number => @notifications.length,
          :more_notifications_url => @more_notifications_url,
          :html => render_to_string({
            :partial => 'list.html.erb'
          })
        }
      }
    end
    mark_seen_notification @notifications
  end

  def recent_notifications
    @recent_notifications = UserNotification.recent_notifications(current_user)

    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'recent_notifications.html.erb'
          )
        }
      end
    end
    mark_seen_notification @recent_notifications
  end

  def unseen_notification
    @number = UserNotification.unseen_notification_count(current_user)

    respond_to do |format|
      format.json do
        render json: {
          notificationNmber: @number
        }
      end
    end
  end

  private

  def mark_seen_notification(notifications)
    notifications.each do |notification|
      notification.seen_by_user(current_user)
    end
  end
end
