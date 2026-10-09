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
      when 'sa-task-files'
        serialize_files(files_of(find_my_module(parent_id)))
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
      serialize_repository_rows(repository_rows, assignable_my_module_id) +
      serialize_files(files)
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

  def files
    filter_files_by_query(
      Asset.where('assets.id IN (?) OR assets.id IN (?)', assets_in_readable_steps, assets_in_readable_results)
           .joins(file_attachment: :blob)
    ).order(updated_at: :desc).limit(LIMIT + 1)
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

  def find_my_module(id)
    MyModule.active
            .readable_by_user(@current_user, @current_team)
            .joins(experiment: :project)
            .where(projects: { archived: false }, experiments: { archived: false })
            .find_by(id: id)
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

  def files_of(my_module)
    return Asset.none unless my_module

    step_asset_ids = my_module.assets_in_steps.select(:id)
    result_asset_ids = my_module.assets_in_results.select(:id)

    filter_files_by_query(
      Asset.where('assets.id IN (?) OR assets.id IN (?)', step_asset_ids, result_asset_ids)
           .joins(file_attachment: :blob)
    ).order(updated_at: :desc).limit(LIMIT + 1)
  end

  def readable_my_module_ids
    MyModule.active
            .readable_by_user(@current_user, @current_team)
            .joins(experiment: :project)
            .where(projects: { archived: false }, experiments: { archived: false })
            .select(:id)
  end

  def assets_in_readable_steps
    Asset.joins(step: :protocol).where(protocols: { my_module_id: readable_my_module_ids }).select(:id)
  end

  def assets_in_readable_results
    Asset.joins(:result).where(results: { my_module_id: readable_my_module_ids }).select(:id)
  end

  def filter_files_by_query(scope)
    return scope if @query.blank?

    sanitized_query = ActiveRecord::Base.sanitize_sql_like(@query)
    scope.where(
      "active_storage_blobs.filename ILIKE :q OR (#{Asset::PREFIXED_ID_SQL}) ILIKE :q",
      q: "%#{sanitized_query}%"
    )
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

  def serialize_files(scope)
    scope.map do |asset|
      {
        id: asset.id,
        id_encoded: asset.id.base62_encode,
        name: sanitize_input(asset.file_name),
        code: asset.code,
        type: 'file',
        updated_at: asset.updated_at
      }
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
