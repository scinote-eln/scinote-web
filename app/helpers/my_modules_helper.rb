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
           when 'atoz' then { file_file_name: :asc }
           when 'ztoa' then { file_file_name: :desc }
           else { created_at: :desc }
           end

    step.assets.order(sort)
  end

  def az_ordered_assets_index(assets, asset_id)
    assets.sort_by(&:file_file_name).map(&:id).index(asset_id)
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
    action_name == "steps"
  end

  def is_results_page?
    action_name == "results"
  end

end
