class UserNotificationsController < ApplicationController
  layout 'main'

  def index
    @last_notification_id = params[:from].to_i || 0
    @per_page = Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT

    @notifications =
      UserNotification.last_notifications(@current_user,
                                          @last_notification_id,
                                          @per_page + 1)

    @more_notifications_url = ''

    @overflown = @notifications.length > @per_page

    @notifications =
      UserNotification.last_notifications(@current_user,
                                          @last_notification_id,
                                          @per_page)

    if @notifications.count > 0
      @more_notifications_url = url_for(
        controller: 'user_notifications',
        action: 'index',
        format: :json,
        from: @notifications.last.id
      )
    end

    respond_to do |format|
      format.html
      format.json do
        render json: {
          per_page: @per_page,
          results_number: @notifications.length,
          more_notifications_url: @more_notifications_url,
          html: render_to_string(partial: 'list.html.erb')
        }
      end
    end
    UserNotification.seen_by_user(current_user)
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
    UserNotification.seen_by_user(current_user)
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
end
