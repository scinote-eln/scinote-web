# frozen_string_literal: true

module Dashboard
  class RecentWorksController < ApplicationController
    def show
      activities = Dashboard::RecentWorkService.new(current_user, current_team, params[:mode]).call
      page = (params[:page] || 1).to_i
      activities = Kaminari.paginate_array(activities).page(page).per(Constants::INFINITE_SCROLL_LIMIT)
      render json: { data: activities, next_page: activities.next_page }
    end
  end
end
