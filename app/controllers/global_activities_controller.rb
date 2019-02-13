class GlobalActivitiesController < ApplicationController
  before_action :set_placeholder_variables, only: [:index]

  def index
  end

  private

  # Whoever will be implementig the filters
  # will delete this method and before action
  def set_placeholder_variables
    @teams = %w(team1 team2 team3)
    @notification_types = %w(notificationType1 notificationType2 notificationType3)
    @activity_types = %w(activityType1 activityType2 activityType3)
    @users = %w(user1 User2 User3 User4)
    @subjects = %w(Subject1 Subject2 Subject3)
  end
end
