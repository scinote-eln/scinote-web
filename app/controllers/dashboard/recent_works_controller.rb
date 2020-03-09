# frozen_string_literal: true

module Dashboard
  class RecentWorksController < ApplicationController
    def show
      activities = Dashboard::RecentWorkService.new(current_user, current_team, params[:mode]).call
      render json: activities
    end
  end
end
