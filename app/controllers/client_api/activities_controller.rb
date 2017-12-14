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
      page = (params[:page] || 1).to_i
      activities = current_user
                   .last_activities
                   .page(page)
                   .per(Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT)
      {
        activities: activities,
        page: page,
        more: !current_user.last_activities.page(page).last_page?,
        timezone: current_user.time_zone
      }
    end
  end
end
