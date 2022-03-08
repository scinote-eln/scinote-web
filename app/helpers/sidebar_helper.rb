module SidebarHelper
  def project_action_to_link_to(project)
    case action_name
    when 'archive', 'module_archive', 'experiment_archive'
      return experiment_archive_project_url(project)
    else
      return project_path(project)
    end
  end

  def experiment_action_to_link_to(experiment)
    case action_name
    when 'archive', 'module_archive', 'experiment_archive'
      return module_archive_experiment_url(experiment)
    else
      return canvas_experiment_path(experiment)
    end
  end

  def module_action_to_link_to(my_module)
    if action_name == 'results'
      results_my_module_url(my_module)
    elsif action_name == 'activities'
      activities_my_module_url(my_module)
    elsif action_name.in?(%w(archive module_archive experiment_archive))
      archive_my_module_url(my_module)
    else
      protocols_my_module_url(my_module)
    end
  end
end
