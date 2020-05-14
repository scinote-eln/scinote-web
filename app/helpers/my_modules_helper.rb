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

  def number_of_samples(my_module)
    my_module.samples.count
  end

  def ordered_result_of(my_module)
    my_module.results.where(archived: false).order(created_at: :desc)
  end

  def get_task_alert_color(my_module)
    alert = ''
    if !my_module.completed?
      alert = ' alert-yellow' if my_module.is_one_day_prior?
      alert = ' alert-red' if my_module.is_overdue?
    elsif my_module.completed?
      alert = ' alert-green'
    end
    alert
  end

  def is_steps_page?
    action_name == 'steps'
  end

  def is_results_page?
    action_name == 'results'
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
               date_time: l(repository.updated_at, format: :full))
    end

    t('my_modules.repository.snapshots.simple_view.live_bottom_label')
  end
end
