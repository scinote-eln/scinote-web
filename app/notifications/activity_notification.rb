# frozen_string_literal: true

# To deliver this notification:
#
# ActivityNotification.with(post: @post).deliver_later(current_user)
# ActivityNotification.with(post: @post).deliver(current_user)

class ActivityNotification < BaseNotification
  include SearchHelper
  include GlobalActivitiesHelper
  include InputSanitizeHelper
  include ActionView::Helpers::TextHelper
  include ApplicationHelper
  include ActiveRecord::Sanitization::ClassMethods
  include Rails.application.routes.url_helpers
  # Add your delivery methods
  #
  # deliver_by :email, mailer: "UserMailer"
  # deliver_by :slack
  # deliver_by :custom, class: "MyDeliveryMethod"

  # Add required params
  #
  # param :post

  def message
    params[:message] if params[:legacy]
  end

  def title
    if params[:legacy]
      params[:title]
    else
      generate_activity_content(activity)
    end
  end

  def subject
    activity.subject unless params[:legacy]
  end
  # def url
  #   post_path(params[:post])
  # end

  private

  def current_team
    @current_team ||= recipient.teams.find_by(id: recipient.current_team_id)
  end

  def current_user
    recipient
  end

  def activity
    @activity ||= Activity.find_by(id: params[:activity_id])
  end
end
