# frozen_string_literal: true

class SmartAnnotation
  LIMIT = Constants::ATWHO_SEARCH_LIMIT

  attr_writer :current_user, :current_team, :query

  def initialize(current_user, current_team, query)
    @current_user = current_user
    @current_team = current_team
    @query = query
  end

  def search(parent_type:, parent_id: nil, assignable_my_module_id: nil, assignable_protocol_id: nil)
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
        parent_id ? serialize_repository_rows(repository_rows_of(find_repository(parent_id)),
                                               assignable_my_module_id, assignable_protocol_id)
                  : serialize_repositories(repositories)
      when 'sa-task-files'
        serialize_files(files_of(find_my_module(parent_id)))
      else
        []
      end

    cap(items)
  end

  def global_search(assignable_my_module_id: nil, assignable_protocol_id: nil)
    items = (
      serialize_projects(projects) +
      serialize_experiments(experiments) +
      serialize_my_modules(my_modules) +
      serialize_repositories(repositories) +
      serialize_repository_rows(repository_rows, assignable_my_module_id, assignable_protocol_id) +
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
           .order(updated_at: :desc)
           .where(archived: false)
  end

  def experiments
    Experiment.search_by_name_and_id(@current_user, @current_team, @query, limit: LIMIT + 1)
              .order(updated_at: :desc)
              .joins(:project)
              .where(projects: { archived: false }, experiments: { archived: false })
  end

  def my_modules
    MyModule.search_by_name_and_id(@current_user, @current_team, @query, limit: LIMIT + 1)
            .active
            .order(updated_at: :desc)
            .joins(experiment: :project)
            .where(projects: { archived: false }, experiments: { archived: false })
  end

  def repositories
    Repository.search_by_name_and_id(@current_user, @current_team, @query, limit: LIMIT + 1)
              .where(archived: false)
              .order(updated_at: :desc)
  end

  def repository_rows
    RepositoryRow.search_by_name_and_id(@current_user, @current_team, @query, limit: LIMIT + 1)
                 .active
                 .order(updated_at: :desc)
                 .joins(:repository)
                 .where(repositories: { archived: false })
  end

  def files
    filter_files_by_query(
      Asset.active
           .where('assets.id IN (?) OR assets.id IN (?)', assets_in_readable_steps(readable_my_module_ids), assets_in_readable_results(readable_my_module_ids))
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

    project.active_experiments.search_by_name_and_id(@current_user, @current_team, @query, limit: LIMIT + 1).order(updated_at: :desc)
  end

  def my_modules_of(experiment)
    return MyModule.none unless experiment

    experiment.my_modules.active.search_by_name_and_id(@current_user, @current_team, @query, limit: LIMIT + 1).order(updated_at: :desc)
  end

  def repository_rows_of(repository)
    return RepositoryRow.none unless repository

    repository.repository_rows.active.search_by_name_and_id(@current_user, @current_team, @query, limit: LIMIT + 1).order(updated_at: :desc)
  end

  def files_of(my_module)
    return Asset.none unless my_module

    step_asset_ids = my_module.assets_in_steps.with_active_step.select(:id)
    result_asset_ids = my_module.assets_in_results.with_active_result.select(:id)

    filter_files_by_query(
      Asset.active
           .where('assets.id IN (?) OR assets.id IN (?)', step_asset_ids, result_asset_ids)
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

  def assets_in_readable_steps(my_module_ids)
    Asset.joins(step: :protocol).with_active_step.where(protocols: { my_module_id: my_module_ids }).select(:id)
  end

  def assets_in_readable_results(my_module_ids)
    Asset.joins(:result).with_active_result.where(results: { my_module_id: my_module_ids }).select(:id)
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
    scope.map { |r| base_item(r, 'prj', r.experiments.any?) }
  end

  def serialize_experiments(scope)
    scope.map { |r| base_item(r, 'exp', r.my_modules.any?) }
  end

  def serialize_my_modules(scope)
    module_ids = scope.reselect(:id)

    step_module_ids = assets_in_readable_steps(module_ids).merge(Asset.active).reselect('protocols.my_module_id')
    result_module_ids = assets_in_readable_results(module_ids).merge(Asset.active).reselect('results.my_module_id')

    scope.select(
      'my_modules.*',
      "(my_modules.id IN (#{step_module_ids.to_sql}) OR " \
      "my_modules.id IN (#{result_module_ids.to_sql})) AS has_active_assets"
    ).map { |r| base_item(r, 'tsk', r.has_active_assets) }
  end

  def serialize_repositories(scope)
    scope.map { |r| base_item(r, 'rep', r.repository_rows.any?) }
  end

  def serialize_repository_rows(scope, assignable_my_module_id, assignable_protocol_id = nil)
    scope.map do |r|
      item = base_item(r, 'rep_item', false)

      if assignable_my_module_id.present?
        item.merge(
          row_assigned: assigned_row_ids(assignable_my_module_id).include?(r.id),
          my_module_id: assignable_my_module_id,
          repository_row_id: r.id
        )
      elsif assignable_protocol_id.present?
        item.merge(
          row_assigned: assigned_protocol_row_ids(assignable_protocol_id).include?(r.id),
          protocol_id: assignable_protocol_id,
          repository_row_id: r.id
        )
      else
        item
      end
    end
  end

  def serialize_files(scope)
    scope.map do |asset|
      {
        id: asset.id,
        id_encoded: asset.id.base62_encode,
        name: asset.file_name,
        display_name: asset.file_title.presence || asset.file_name,
        code: asset.code,
        type: 'file',
        pdf: asset.pdf?,
        updated_at: asset.updated_at,
        has_children: false
      }
    end
  end

  def assigned_row_ids(my_module_id)
    @assigned_row_ids ||= {}
    @assigned_row_ids[my_module_id] ||=
      MyModuleRepositoryRow.where(my_module_id: my_module_id).pluck(:repository_row_id).to_set
  end

  def assigned_protocol_row_ids(protocol_id)
    @assigned_protocol_row_ids ||= {}
    @assigned_protocol_row_ids[protocol_id] ||=
      ProtocolRepositoryRow.where(protocol_id: protocol_id).pluck(:repository_row_id).to_set
  end

  def base_item(record, type, has_children)
    {
      id: record.id,
      id_encoded: record.id.base62_encode,
      name: record.name,
      code: record.code,
      type: type,
      updated_at: record.updated_at,
      has_children: has_children
    }
  end
end
