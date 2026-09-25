class AtWhoController < ApplicationController
  before_action :load_vars
  before_action :check_users_permissions

  def users
    scope = @team.search_users(@query).limit(Constants::ATWHO_SEARCH_LIMIT + 1)
    @users = scope.limit(Constants::ATWHO_SEARCH_LIMIT)
    @limit_reached = limit_reached?(scope)
  end

  def menu_items
    @res = SmartAnnotation.new(current_user, current_team, @query)
  end

  def rep_items
    repository = resolve_repository(params[:repository_id])
    rows = []
    @repository_id = nil

    if repository && can_read_repository?(repository)
      rows = SmartAnnotation.new(current_user, current_team, @query)
                            .repository_rows(repository, assignable_my_module_id)
      @repository_id = repository.id
    end

    @rows = rows.take(Constants::ATWHO_SEARCH_LIMIT)
    @limit_reached = limit_reached?(rows)
  end

  def menu
    @repositories = Repository.active.readable_by_user(current_user, @team)
  end

  def projects
    scope = SmartAnnotation.new(current_user, current_team, @query).projects
    @projects = scope.limit(Constants::ATWHO_SEARCH_LIMIT)
    @limit_reached = limit_reached?(scope)
  end

  def experiments
    scope = SmartAnnotation.new(current_user, current_team, @query).experiments
    @groups = group_by_project(scope.limit(Constants::ATWHO_SEARCH_LIMIT))
    @limit_reached = limit_reached?(scope)
  end

  def my_modules
    scope = SmartAnnotation.new(current_user, current_team, @query).my_modules
    @groups = group_by_project_and_experiment(scope.limit(Constants::ATWHO_SEARCH_LIMIT))
    @limit_reached = limit_reached?(scope)
  end

  private

  def load_vars
    @team = Team.find_by_id(params[:id])
    @query = params[:query]
    @team_id = current_team&.id
    render_404 unless @team
  end

  def check_users_permissions
    render_403 unless can_read_team?(@team)
  end

  def limit_reached?(collection)
    collection.length == Constants::ATWHO_SEARCH_LIMIT + 1
  end

  def resolve_repository(repository_id)
    if repository_id.present?
      Repository.find_by(id: repository_id)
    else
      Repository.active.readable_by_user(current_user, @team).first
    end
  end

  def assignable_my_module_id
    return unless params[:assignable_my_module_id].present?

    MyModule.readable_by_user(current_user, @team).find_by(id: params[:assignable_my_module_id])&.id
  end

  def group_by_project(records)
    records.joins(:project)
           .select('projects.name AS project_name', "#{records.table_name}.*")
           .group_by(&:project_name)
           .map { |project_name, group_records| { project_name: project_name, records: group_records } }
  end

  def group_by_project_and_experiment(records)
    records.joins(experiment: :project)
           .select('projects.name AS project_name', 'experiments.name AS experiment_name', "#{records.table_name}.*")
           .group_by { |record| [record.project_name, record.experiment_name] }
           .map do |(project_name, experiment_name), group_records|
      { project_name: project_name, experiment_name: experiment_name, records: group_records }
    end
  end
end
