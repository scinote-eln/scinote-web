module MyModulesHelper
  def ordered_step_of(my_module)
    my_module.steps.order(:position)
  end

  def ordered_checklist_items(checklist)
    checklist.checklist_items.order(:position)
  end

  def ordered_assets(step)
    step.assets.order(:file_updated_at)
  end

  def number_of_samples(my_module)
    my_module.samples.count
  end

  def ordered_result_of(my_module)
    my_module.results.where(archived: false).order(created_at: :desc)
  end

  def is_steps_page?
    action_name == "steps"
  end

  def is_results_page?
    action_name == "results"
  end

end
