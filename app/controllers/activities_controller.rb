class ActivitiesController < ApplicationController
  include ActivityHelper

  def index
    @vars = local_vars
    respond_to do |format|
      format.json do
        render json: {
          more_url: local_vars.fetch(:more_activities_url),
          html: render_to_string(
            partial: 'list.html.erb', locals: @vars
          )
        }
      end
      format.html
    end
  end

  private

  def local_vars
    page = (params[:page] || 1).to_i
    activities = current_user.last_activities
                             .page(page)
                             .per(Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT)
    unless activities.blank? || activities.last_page?
      more_url = url_for(
        activities_url(
          format: :json,
          page: page + 1,
          last_activity: activities.last.id
        )
      )
    end
    # send last activity date of the previus batch
    previous_activity = Activity.find_by_id(params[:last_activity])
    previus_date = previous_activity.created_at.to_date if previous_activity
    {
      activities: activities,
      more_activities_url: more_url,
      page: page,
      previous_activity_created_at: previus_date
    }
  end
end
