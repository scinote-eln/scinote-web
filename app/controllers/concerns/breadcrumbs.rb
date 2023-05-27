# frozen_string_literal: true

module Breadcrumbs
  extend ActiveSupport::Concern

  included do
    def set_breadcrumbs_items
      my_module = @my_module
      experiment = my_module&.experiment || @experiment
      project = experiment&.project || @project
      current_folder = project&.project_folder || @current_folder
      @breadcrumbs_items = []

      folders = helpers.tree_ordered_parent_folders(current_folder)

      @breadcrumbs_items.push({
                                label: t('projects.index.breadcrumbs_root'),
                                url: projects_path(view_mode: project&.archived? ? :archived : :active)
                              })

      folders&.each do |project_folder|
        @breadcrumbs_items.push({
                                  label: project_folder.name,
                                  url: project_folder_path(project_folder)
                                })
      end

      include_project(project) if project

      include_experiment(experiment) if experiment

      include_my_module(my_module) if my_module

      archived_exists = @breadcrumbs_items.any? { |item| item[:archived] == true }

      if params[:view_mode] == 'archived' || archived_exists
        @breadcrumbs_items.each do |item|
          item[:label] = "(A) #{item[:label]}"
        end
      end
      @breadcrumbs_items
    end
  end

  private

  def include_project(project)
    @breadcrumbs_items.push({
                              label: project.name,
                              url: project_path(project),
                              archived: project.archived?
                            })
  end

  def include_experiment(experiment)
    @breadcrumbs_items.push({
                              label: experiment.name,
                              url: my_modules_experiment_path(experiment),
                              archived: experiment.archived?
                            })
  end

  def include_my_module(my_module)
    @breadcrumbs_items.push({
                              label: my_module.name,
                              url: my_module_path(my_module),
                              archived: my_module.archived?
                            })
  end
end
