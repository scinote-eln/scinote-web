module SecondaryNavigationHelper
  def project_info?
    action_name == 'show'
  end

  def project_show?
    action_name == 'show'
  end

  def project_samples?
    action_name == 'samples'
  end

  def project_archive?
    action_name == 'experiment_archive'
  end

  def experiment_canvas?
    action_name == 'canvas'
  end

  def experiment_archive?
    action_name == 'module_archive'
  end

  def experiment_samples?
    action_name == 'samples'
  end

  def module_overview?
    action_name == 'show'
  end

  def module_protocols?
    action_name == 'protocols'
  end

  def module_results?
    action_name == 'results'
  end

  def module_activities?
    action_name == 'activities'
  end

  def module_samples?
    action_name == 'samples'
  end
end
