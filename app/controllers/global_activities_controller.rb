# frozen_string_literal: true

class GlobalActivitiesController < ApplicationController

  def index
    teams = activity_filters[:teams]
    teams = current_user.teams if teams.blank?
    @teams = teams
    @activity_types = Activity.activity_types_list
    @users = UserTeam.my_employees(current_user)
    @grouped_activities, more_activities =
      ActivitiesService.load_activities(teams, activity_filters)
    respond_to do |format|
      format.json do
        render json: {
          activities_html: @grouped_activities,
          from: @grouped_activities.keys.first,
          to: @grouped_activities.keys.last,
          more_activities: more_activities
        }
      end
      format.html do
      end
    end
  end

  def search_subjects
    query = subject_search_params[:query]
    teams =
      if subject_search_params[:teams].present?
        current_user.teams.where(id: subject_search_params[:teams])
      else
        current_user.teams
      end
    subject_types =
      if subject_search_params[:subject_types].present?
        Extends::SEARCHABLE_ACTIVITY_SUBJECT_TYPES &
          subject_search_params[:subject_types]
      else
        Extends::SEARCHABLE_ACTIVITY_SUBJECT_TYPES
      end
    results = {}
    subject_types.each do |subject|
      matched = subject.constantize
                       .search_by_name(current_user, teams, query)
                       .limit(Constants::SEARCH_LIMIT)
                       .pluck(:id, :name)
      next if matched.length.zero?
      results[subject] = matched.map { |pr| { id: pr[0], name: pr[1] } }
    end
    respond_to do |format|
      format.json do
        render json: results
      end
    end
  end

  private

  def activity_filters
    params.permit(
      :from_date, :to_date, types: [], subjects: [], users: [], teams: []
    )
  end

  def subject_search_params
    params.permit(:query, teams: [], subject_types: [])
  end
end
