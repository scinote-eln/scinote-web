module ClientApi
  class ActivitiesController < ApplicationController
    include ActivityHelper
    before_action :load_vars

    def index
      @per_page =
      @activities = current_user.last_activities(@last_activity_id,
        Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT)

      respond_to do |format|
        format.json do
          render template: '/client_api/activities/index',
                 status: :ok,
                 locals: { activities: @activities }
        end
      end
    end

    private

    def load_vars
      @last_activity_id = params[:from].to_i || 0
      @last_activity = Activity.find_by_id(@last_activity_id)
    end
  end
end
