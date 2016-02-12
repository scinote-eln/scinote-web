module ApplicationHelper

  def is_module_page?
    controller_name == "my_modules"
  end

  def is_project_page?
    controller_name == "projects" or
    (controller_name == "reports" and action_name == "index")
  end

  def is_project_activities_page?
    controller_name == "project_activities"
  end

end
