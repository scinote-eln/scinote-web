module ClientApi
  class ActivitiesController < ApplicationController

    def index
      respond_to do |format|
        format.json do
          render template: '/client_api/activities/index',
                 status: :ok,
                 locals: activities_vars
        end
      end
    end

    private

    def activities_vars
      last_activity_id = params[:from].to_i || 0
      per_page = Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT
      activities = current_user.last_activities(last_activity_id, per_page + 1)
      more = activities.length > per_page
      { activities: activities, more: more }
    end
  end
end
