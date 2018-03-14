module LeftMenuBarHelper
  def projects_are_selected?
    controller_name.in? %w(projects experiments my_modules)
  end

  def repositories_are_selected?
    controller_name == 'repositories'
  end

  def templates_are_selected?
    # TBD
    controller_name == 'protocols'
  end

  def reports_are_selected?
    # TBD
    controller_name == 'reports'
  end

  def settings_are_selected?
    controller_name.in? %(registrations preferences addons teams)
  end

  def activities_are_selected?
    controller_name == 'activities'
  end

  def help_is_selected?
    # TBD
  end
end
