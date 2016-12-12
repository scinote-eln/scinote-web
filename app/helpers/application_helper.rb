module ApplicationHelper
  def module_page?
    controller_name == 'my_modules'
  end

  def experiment_page?
    controller_name == 'experiments'
  end

  def project_page?
    controller_name == 'projects' ||
      (controller_name == 'reports' && action_name == 'index')
  end

  def sample_types_page_project?
    controller_name == 'sample_types' && !(defined? @my_module)
  end

  def sample_groups_page_project?
    controller_name == 'sample_groups' && !(defined? @my_module)
  end

  def sample_types_page_my_module?
    controller_name == 'sample_types' && defined? @my_module
  end

  def sample_groups_page_my_module?
    controller_name == 'sample_groups' && defined? @my_module
  end
end
