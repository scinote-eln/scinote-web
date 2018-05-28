module SecondaryNavigationHelper

  def is_all_projects_index?
    action_name == 'index'
  end

  def is_all_projects_archive?
    action_name == 'archive'
  end

  def is_project_info?
    action_name == 'show'
  end

  def is_project_show?
    action_name == 'show'
  end

  def is_project_samples?
    action_name == 'samples'
  end

  def is_project_reports?
    controller_name == 'reports' && action_name == 'index'
  end

  def is_project_archive?
    action_name == 'experiment_archive'
  end

  def is_experiment_canvas?
    action_name == 'canvas'
  end

  def is_experiment_archive?
    action_name == 'module_archive'
  end

  def is_experiment_samples?
    action_name == 'samples'
  end

  def is_module_info?
    action_name == 'show'
  end

  def is_module_protocols?
    action_name == 'protocols'
  end

  def is_module_results?
    action_name == 'results'
  end

  def is_module_activities?
    action_name == 'activities'
  end

  def is_module_samples?
    action_name == 'samples'
  end

  def is_module_archive?
    action_name == 'archive'
  end

  def title_element
    if all_projects_page?
      current_team
    elsif project_page?
      @project
    elsif experiment_page?
      @experiment
    elsif module_page?
      @my_module
    end
  end
end
