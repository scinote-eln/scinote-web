module SecondaryNavigationHelper

  def is_project_info?
    action_name == "show"
  end

  def is_project_canvas?
    action_name == "canvas"
  end

  def is_project_samples?
    action_name == "samples"
  end

  def is_project_activities?
    controller_name == "project_activities" and action_name == "index"
  end

  def is_project_reports?
    controller_name == "reports" and action_name == "index"
  end

  def is_project_archive?
    action_name == "module_archive"
  end

  def is_module_info?
    action_name == "show"
  end

  def is_module_steps?
    action_name == "steps"
  end

  def is_module_results?
    action_name == "results"
  end

  def is_module_activities?
    action_name == "activities"
  end

  def is_module_samples?
    action_name == "samples"
  end

  def is_module_archive?
    action_name == "archive"
  end
end
