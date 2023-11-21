# frozen_string_literal: true

class ActivityNotification < BaseNotification
  include SearchHelper
  include GlobalActivitiesHelper
  include InputSanitizeHelper
  include ActionView::Helpers::TextHelper
  include ApplicationHelper
  include ActiveRecord::Sanitization::ClassMethods
  include Rails.application.routes.url_helpers

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
