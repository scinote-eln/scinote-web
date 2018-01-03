class ActivitiesController < ApplicationController
  include ActivityHelper

  def index
    respond_to do |format|
      format.json do
        render json: {
          more_url: local_vars.fetch(:more_activities_url),
          html: render_to_string(
            partial: 'index.html.erb', locals: local_vars
          )
        }
      end
    end
  end

  private

  def local_vars
    page = (params[:page] || 1).to_i
    activities = current_user.last_activities
                             .page(page)
                             .per(Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT)
    unless activities.last_page?
      more_url = url_for(activities_url(format: :json, page: page + 1))
    end
    {
      activities: activities,
      more_activities_url: more_url,
      page: page
    }
  end
end
