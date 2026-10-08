# frozen_string_literal: true

class SmartAnnotation
  include InputSanitizeHelper

  LIMIT = Constants::ATWHO_SEARCH_LIMIT

  attr_writer :current_user, :current_team, :query

  def initialize(current_user, current_team, query)
    @current_user = current_user
    @current_team = current_team
    @query = query
  end

  def search(parent_type:, parent_id: nil, assignable_my_module_id: nil)
    items =
      case parent_type
      when 'sa-projects'
        parent_id ? serialize_experiments(experiments_of(find_project(parent_id)))
                  : serialize_projects(projects)
      when 'sa-experiments'
        parent_id ? serialize_my_modules(my_modules_of(find_experiment(parent_id)))
                  : serialize_experiments(experiments)
      when 'sa-tasks'
        serialize_my_modules(my_modules)
      when 'sa-repositories'
        parent_id ? serialize_repository_rows(repository_rows_of(find_repository(parent_id)), assignable_my_module_id)
                  : serialize_repositories(repositories)
      else
        []
      end

    cap(items)
  end

  def global_search(assignable_my_module_id: nil)
    items = (
      serialize_projects(projects) +
      serialize_experiments(experiments) +
      serialize_my_modules(my_modules) +
      serialize_repositories(repositories) +
      serialize_repository_rows(repository_rows, assignable_my_module_id)
    ).sort_by { |item| item[:updated_at] }.reverse

    cap(items)
  end

  private

  def cap(items)
    { items: items.first(LIMIT), limit_reached: items.length > LIMIT }
  end

  # ---- relations: unscoped (root listing of a type / global search) -------------------------

  def projects
    Project.search_by_name_and_id(@current_user, @current_team, @query, limit: LIMIT + 1)
           .where(archived: false)
  end

  def experiments
    Experiment.search_by_name_and_id(@current_user, @current_team, @query, limit: LIMIT + 1)
              .joins(:project)
              .where(projects: { archived: false }, experiments: { archived: false })
  end

  def my_modules
    MyModule.search_by_name_and_id(@current_user, @current_team, @query, limit: LIMIT + 1)
            .active
            .joins(experiment: :project)
            .where(projects: { archived: false }, experiments: { archived: false })
  end

  def repositories
    Repository.search_by_name_and_id(@current_user, @current_team, @query, limit: LIMIT + 1)
              .where(archived: false)
  end

  def repository_rows
    RepositoryRow.search_by_name_and_id(@current_user, @current_team, @query, limit: LIMIT + 1)
                 .active
                 .joins(:repository)
                 .where(repositories: { archived: false })
  end

  # ---- parent resolution + children (drill-down) ---------------------------------------------

  def find_project(id)
    Project.active.readable_by_user(@current_user, @current_team).find_by(id: id)
  end

  def find_experiment(id)
    Experiment.is_archived(false).readable_by_user(@current_user, @current_team).find_by(id: id)
  end

  def find_repository(id)
    Repository.active.readable_by_user(@current_user, @current_team).find_by(id: id)
  end

  def experiments_of(project)
    return Experiment.none unless project

    project.active_experiments.search_by_name_and_id(@current_user, @current_team, @query, limit: LIMIT + 1)
  end

  def my_modules_of(experiment)
    return MyModule.none unless experiment

    experiment.my_modules.active.search_by_name_and_id(@current_user, @current_team, @query, limit: LIMIT + 1)
  end

  def repository_rows_of(repository)
    return RepositoryRow.none unless repository

    repository.repository_rows.active.search_by_name_and_id(@current_user, @current_team, @query, limit: LIMIT + 1)
  end

  # ---- serialization ---------------------------------------------------------------------------

  def serialize_projects(scope)
    scope.map { |r| base_item(r, 'prj') }
  end

  def serialize_experiments(scope)
    scope.map { |r| base_item(r, 'exp') }
  end

  def serialize_my_modules(scope)
    scope.map { |r| base_item(r, 'tsk') }
  end

  def serialize_repositories(scope)
    scope.map { |r| base_item(r, 'rep') }
  end

  def serialize_repository_rows(scope, assignable_my_module_id)
    scope.map do |r|
      item = base_item(r, 'rep_item')
      next item unless assignable_my_module_id.present?

      item.merge(
        row_assigned: assigned_row_ids(assignable_my_module_id).include?(r.id),
        my_module_id: assignable_my_module_id,
        repository_row_id: r.id
      )
    end
  end

  def assigned_row_ids(my_module_id)
    @assigned_row_ids ||= {}
    @assigned_row_ids[my_module_id] ||=
      MyModuleRepositoryRow.where(my_module_id: my_module_id).pluck(:repository_row_id).to_set
  end

  def base_item(record, type)
    {
      id: record.id,
      id_encoded: record.id.base62_encode,
      name: sanitize_input(record.name),
      code: record.code,
      type: type,
      updated_at: record.updated_at
    }
  end
end
