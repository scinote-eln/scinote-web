# frozen_string_literal: true

module MyModulesListPartialHelper
  def my_modules_list_partial(my_modules)
    ungrouped_tasks = my_modules.joins(experiment: :project)
                                .select('experiments.name as experiment_name,
                                         experiments.archived as experiment_archived,
                                         projects.name as project_name,
                                         projects.archived as project_archived,
                                         my_modules.*')
    ungrouped_tasks.group_by { |i| [i[:project_name], i[:experiment_name]] }.map do |group, tasks|
      {
        project_name: group[0],
        project_archived: tasks[0]&.project_archived,
        experiment_name: group[1],
        experiment_archived: tasks[0]&.experiment_archived,
        tasks: tasks
      }
    end
  end
end
