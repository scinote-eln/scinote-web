# frozen_string_literal: true

class GlobalActivitiesController < ApplicationController
  include InputSanitizeHelper

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
    selected_teams = if activity_filters[:teams].present?
                       @teams.where(id: activity_filters[:teams]).order(name: :asc)
                     else
                       @teams.order(name: :asc)
                     end
    @activity_types = Activity.activity_types_list
    @user_list = User.where(id: UserTeam.where(team: current_user.teams).select(:user_id))
                     .distinct
                     .order(full_name: :asc)
                     .pluck(:full_name, :id)

    activities = ActivitiesService.load_activities(current_user, selected_teams, activity_filters)

    @grouped_activities = activities.group_by do |activity|
      Time.zone.at(activity.created_at).to_date.to_s
    end

    @next_page = activities.next_page
    @starting_timestamp = activities.first&.created_at.to_i

    respond_to do |format|
      format.json do
        render json: {
          activities_html: render_to_string(
            partial: 'activity_list.html.erb'
          ),
          next_page: @next_page,
          starting_timestamp: @starting_timestamp
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

  def project_filter
    render json: get_objects(Project)
  end

  def experiment_filter
    render json: get_objects(Experiment)
  end

  def my_module_filter
    render json: get_objects(MyModule)
  end

  def inventory_filter
    render json: get_objects(Repository)
  end

  def inventory_item_filter
    render json: get_objects(RepositoryRow)
  end

  def protocol_filter
    render json: get_objects(Protocol)
  end

  def report_filter
    render json: get_objects(Report)
  end

  private

  def get_objects(subject)
    query = subject_search_params[:query]
    teams =
      if subject_search_params[:teams].present?
        current_user.teams.where(id: subject_search_params[:teams])
      else
        current_user.teams
      end
    filter_teams =
      if subject_search_params[:users].present?
        User.where(id: subject_search_params[:users]).joins(:user_teams).group(:team_id).pluck(:team_id)
      elsif subject_search_params[:teams].present?
        subject_search_params[:teams]
      else
        teams
      end
    matched = subject.search_by_name(current_user, teams, query, whole_phrase: true)
                     .where.not(name: nil).where.not(name: '')
                     .filter_by_teams(filter_teams)
                     .order(name: :asc)

    selected_subject = subject_search_params[:subjects]
    matched = matched.where(project_id: selected_subject['Project']) if subject == Experiment
    matched = matched.where(experiment_id: selected_subject['Experiment']) if subject == MyModule
    matched = matched.where(repository_id: selected_subject['Repository']) if subject == RepositoryRow

    matched = matched.limit(Constants::SEARCH_LIMIT).pluck(:id, :name)
    matched.map { |pr| { value: pr[0], label: escape_input(pr[1]) } }
  end

  def activity_filters
    params.permit(
      :page, :starting_timestamp, :from_date, :to_date, types: [], subjects: {}, users: [], teams: []
    )
  end

  def subject_search_params
    params.permit(:query, teams: [], subject_types: [], users: [], subjects: {})
  end
end
