module SidebarHelper

  def currently_active?(my_module)
      @my_module.present? and @my_module.id == my_module.id
  end

  def is_canvas?
    action_name == "canvas"
  end

  def project_action_to_link_to(project)
    case action_name
    when "samples"
      return samples_project_path(project)
    when "archive"
      return experiment_archive_project_url(project)
    else
      return project_path(project)
    end
  end

  def module_action_to_link_to(my_module)
    case action_name
    when "results"
      return results_my_module_url(my_module)
    when "activities"
      return activities_my_module_url(my_module)
    when "samples"
      return samples_my_module_url(my_module)
    when "archive", "module_archive"
      return archive_my_module_url(my_module)
    else
      return protocols_my_module_url(my_module)
    end
  end
end
