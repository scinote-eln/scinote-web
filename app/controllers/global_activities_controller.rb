# frozen_string_literal: true

class GlobalActivitiesController < ApplicationController
  def index
    # Preload filter format
    #   {
    #     from_date: "YYYY-MM-DD",
    #     to_date: "YYYY-MM-DD",
    #     teams: [*team_ids],
    #     types: [*activity_type_ids],
    #     users: [*user_ids],
    #     subjects: {
    #       *Object_name: [*object_ids],
    #       ...
    #     }
    #   }

    # Example
    #   {
    #     from_date: "2019-03-29",
    #     to_date: "2019-03-29",
    #     teams: [1,2],
    #     types: [32,33,34],
    #     users: [1,2,3],
    #     subjects: {
    #       Project: [1]
    #     }
    #   }
    #
    # To prepare URL search query use - Activity.url_search_query(filter)
    @filters = activity_filters
    @filters[:subject_labels] = params[:subject_labels]
    @teams = current_user.teams
    selected_teams = if request.format.html?
                       current_team
                     elsif activity_filters[:teams].present?
                       @teams.where(id: activity_filters[:teams]).order(name: :asc)
                     else
                       @teams.order(name: :asc)
                     end
    @activity_types = Activity.activity_types_list
    @user_list = User.where(id: UserTeam.where(team: current_user.teams).select(:user_id))
                     .distinct
                     .order(full_name: :asc)
                     .pluck(:full_name, :id)
    @grouped_activities, @more_activities =
      ActivitiesService.load_activities(current_user, selected_teams, activity_filters)
    last_day = @grouped_activities.keys.last
    @next_date = (Date.parse(last_day) - 1.day).strftime('%Y-%m-%d') if last_day
    respond_to do |format|
      format.json do
        render json: {
          activities_html: render_to_string(
            partial: 'activity_list.html.erb'
          ),
          from: @next_date,
          more_activities: @more_activities
        }
      end
      format.html do
      end
    end
  end

  def team_filter
    render json: current_user.teams.global_activity_filter(activity_filters, params[:query])
  end

  def user_filter
    filter = activity_filters
    filter = { subjects: { MyModule: [params[:my_module_id].to_i] } } if params[:my_module_id]
    render json: current_user.global_activity_filter(filter, params[:query])
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
    filter_teams =
      if subject_search_params[:users].present?
        User.where(id: subject_search_params[:users]).joins(:user_teams).group(:team_id).pluck(:team_id)
      elsif subject_search_params[:teams].present?
        subject_search_params[:teams]
      else
        []
      end
    results = {}
    subject_types.each do |subject|
      matched = subject.constantize
                       .search_by_name(current_user, teams, query, whole_phrase: true)
                       .filter_by_teams(filter_teams)
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
      :from_date, :to_date, types: [], subjects: {}, users: [], teams: []
    )
  end

  def subject_search_params
    params.permit(:query, teams: [], subject_types: [], users: [])
  end
end
