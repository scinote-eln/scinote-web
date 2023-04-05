# frozen_string_literal: true

module Breadcrumbs
  extend ActiveSupport::Concern

  included do
    def set_breadcrumbs_items
      my_module = @my_module
      experiment = my_module&.experiment || @experiment
      project = experiment&.project || @project
      p '====================='
      p @project
      current_folder = project&.project_folder
      @breadcrumbs_items = []

      folders = helpers.tree_ordered_parent_folders(current_folder)

      @breadcrumbs_items.push({
                                label: t('projects.index.breadcrumbs_root'),
                                url: projects_path,
                                class: 'project-folder-link'
                              })

      folders&.each do |project_folder|
        @breadcrumbs_items.push({
                                  label: project_folder.name,
                                  url: project_folder_path(project_folder),
                                  class: 'project-folder-link'
                                })
      end

      if project
        @breadcrumbs_items.push({
                                  label: project.name,
                                  url: project_path(project),
                                  archived: project.archived?
                                })
      end

      if experiment
        @breadcrumbs_items.push({
                                  label: experiment.name,
                                  url: my_modules_experiment_path(experiment),
                                  archived: experiment.archived?
                                })
      end

      if my_module
        @breadcrumbs_items.push({
                                  label: my_module.name,
                                  url: my_module_path(my_module),
                                  archived: my_module.archived?
                                })
      end
    end
  end
end
