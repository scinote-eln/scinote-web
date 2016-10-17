class ActivitiesController < ApplicationController
  before_filter :load_vars

  def index
    @per_page = Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT
    @activities = current_user.last_activities(@last_activity_id,
      @per_page + 1)

    @overflown = @activities.length > @per_page

    @activities = current_user.last_activities(@last_activity_id,
      @per_page)

    # Whether to hide date labels
    @hide_today = params.include? :from
    @day = @last_activity.present? ?
      @last_activity.created_at.strftime("%j").to_i :
      366

    more_url = url_for(activities_url(format: :json,
      from: @activities.last.id))
    respond_to do |format|
      format.json {
        render :json => {
          per_page: @per_page,
          activities_number: @activities.length,
          next_url: more_url,
          html: render_to_string({
            partial: 'index.html.erb',
            locals: {
              more_activities_url: more_url,
              hide_today: @hide_today,
              day: @day
            }
          })
        }
      }
    end
  end

  def load_vars
    @last_activity_id = params[:from].to_i || 0
    @last_activity = Activity.find_by_id(@last_activity_id)
  end
end
