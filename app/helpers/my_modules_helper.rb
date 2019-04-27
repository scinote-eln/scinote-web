module MyModulesHelper
  def ordered_step_of(my_module)
    my_module.protocol.steps.order(:position)
  end

  def ordered_checklist_items(checklist)
    checklist.checklist_items.order(:position)
  end

  def ordered_assets(step)
    assets=[]
    assets += step.assets
    assets += step.marvin_js_assets
    assets.sort! { |a, b| 
      a[asset_date_sort_field(a)] <=> b[asset_date_sort_field(b)] 
    }
  end

  def az_ordered_assets_index(step, asset_id)
    assets=[]
    assets += step.assets
    assets += step.marvin_js_assets
    assets.sort! { |a, b| 
      (a[asset_name_sort_field(a)] || '').downcase <=> (b[asset_name_sort_field(b)] || '').downcase
    }.pluck(:id).index(asset_id)
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

  private

  def asset_date_sort_field(el)
    result = {
      'Asset' => :file_updated_at,
      'MarvinJsAsset' => :updated_at
    }
    result[el.class.name]
  end

  def asset_name_sort_field(el)
    result = {
      'Asset' => :file_file_name,
      'MarvinJsAsset' => :name
    }
    result[el.class.name]
  end

end
