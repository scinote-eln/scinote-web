# Tasks

def visit_task_page(task_name) # /modules/:id/
  m = MyModule.find_by(name: task_name)
  visit protocols_my_module_path(m)
end

def visit_task_results_page(task_name) # /modules/:id/results
  m = MyModule.find_by(name: task_name)
  visit results_my_module_path(m)
end

def visit_task_archived_results_page(task_name) # /modules/:id/archive
  m = MyModule.find_by(name: task_name)
  visit archive_my_module_path(m)
end


# Settings
def visit_profile_page
  visit edit_user_registration_path
end

def visit_preferences_page
  visit preferences_path
end

def visit_addons_page
  visit addons_path
end

def visit_team_settings_page(team_name)
  t = Team.find_by(name: team_name)
  visit team_path(t)
end

# Project

def visit_project_page(project_name)
  p = Project.find_by(name: project_name)
  visit project_path(p)
end

# Experiment

def visit_canvas_page(experiment_name)
  e = Experiment.find_by(name: experiment_name)
  visit canvas_experiment_path(e)
end

# Reports

def reports_page
  visit reports_path
end

# Inventories

def inventories_page
  visit repositories_path
end


def inventory_page(inventory_name)
  i = Repository.find_by(name: inventory_name)
  visit repository_path(i)
end
