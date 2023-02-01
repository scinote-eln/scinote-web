# frozen_string_literal: true

module MyModulesHelper
  def ordered_step_of(my_module)
    my_module.protocol.steps.order(:position)
  end

  def ordered_checklist_items(checklist)
    checklist.checklist_items.order(:position)
  end

  def ordered_assets(step)
    view_state = step.current_view_state(current_user)
    sort = case view_state.state.dig('assets', 'sort')
           when 'old' then { created_at: :asc }
           when 'atoz' then { 'active_storage_blobs.filename': :asc }
           when 'ztoa' then { 'active_storage_blobs.filename': :desc }
           else { created_at: :desc }
           end

    step.assets.joins(file_attachment: :blob).order(sort)
  end

  def az_ordered_assets_index(step, asset_id)
    step.assets
        .joins(file_attachment: :blob)
        .order(Arel.sql('LOWER(active_storage_blobs.filename)'))
        .pluck(:id)
        .index(asset_id) || 0
  end

  def get_task_alert_color(my_module)
    alert = ''
    if !my_module.archived_branch? && !my_module.completed?
      alert = ' alert-yellow' if my_module.is_one_day_prior?
      alert = ' alert-red' if my_module.is_overdue?
    end
    alert
  end

  def is_steps_page?
    action_name == 'steps'
  end

  def is_results_page?
    action_name == 'results'
  end

  def grouped_by_prj_exp(my_modules)
    ungrouped_tasks = my_modules.joins(experiment: :project)
                                .select('experiments.name as experiment_name,
                                         experiments.archived as experiment_archived,
                                         projects.name as project_name,
                                         projects.archived as project_archived,
                                         my_modules.*')
    ungrouped_tasks.group_by { |i| [i[:project_name], i[:experiment_name]] }.map do |group, tasks|
      {
        project_name: group[0],
        project_archived: tasks[0]&.project_archived,
        experiment_name: group[1],
        experiment_archived: tasks[0]&.experiment_archived,
        tasks: tasks
      }
    end
  end

  def assigned_repository_full_view_table_path(my_module, repository)
    if repository.is_a?(RepositorySnapshot)
      return full_view_table_my_module_repository_snapshot_path(my_module, repository)
    end

    full_view_table_my_module_repository_path(my_module, repository)
  end

  def assigned_repository_simple_view_index_path(my_module, repository)
    return index_dt_my_module_repository_snapshot_path(my_module, repository) if repository.is_a?(RepositorySnapshot)

    index_dt_my_module_repository_path(my_module, repository)
  end

  def assigned_repository_simple_view_footer_label(repository)
    if repository.is_a?(RepositorySnapshot)
      return t('my_modules.repository.snapshots.simple_view.snapshot_bottom_label',
               date_time: l(repository.created_at, format: :full))
    end

    t('my_modules.repository.snapshots.simple_view.live_bottom_label')
  end

  def assigned_repository_simple_view_name_column_id(repository)
    repository.is_a?(RepositorySnapshot) ? 2 : 3
  end

  def my_module_archived_on(my_module)
    if my_module.archived?
      my_module.archived_on
    elsif my_module.experiment.archived?
      my_module.experiment.archived_on
    elsif my_module.experiment.project.archived?
      my_module.experiment.project.archived_on
    end
  end

  def my_module_due_status(my_module, datetime = DateTime.current)
    return if my_module.archived_branch? || my_module.completed?

    if my_module.is_overdue?(datetime)
      I18n.t('my_modules.details.overdue')
    elsif my_module.is_one_day_prior?(datetime)
      I18n.t('my_modules.details.due_soon')
    else
      ''
    end
  end
end
