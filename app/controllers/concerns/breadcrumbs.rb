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
      archived_branch = project&.archived? ||
                        current_folder&.archived? ||
                        (!project && params[:view_mode] == 'archived')

      @breadcrumbs_items.push({
                                label: t('projects.index.breadcrumbs_root'),
                                url: projects_path(view_mode: archived_branch ? :archived : :active),
                                archived: archived_branch
                              })

      folders&.each do |project_folder|
        archived_branch = project_folder.archived_branch?
        @breadcrumbs_items.push({
                                  label: project_folder.name,
                                  url: project_folder_path(project_folder,
                                                           view_mode: archived_branch ? :archived : :active),
                                  archived: archived_branch
                                })
      end

      include_project(project) if project

      include_experiment(experiment) if experiment

      include_my_module(my_module) if my_module

      @breadcrumbs_items.each do |item|
        item[:label] = "(A) #{item[:label]}" if item[:archived]
      end
      @breadcrumbs_items
    end
  end

  private

  def include_project(project)
    archived_branch = project.archived?
    @breadcrumbs_items.push(
      {
        label: project.name,
        url: experiments_path(project_id: project, view_mode: archived_branch ? :archived : :active),
        archived: archived_branch
      }
    )
  end

  def include_experiment(experiment)
    archived_branch = experiment.archived_branch?
    @breadcrumbs_items.push(
      {
        label: experiment.name,
        url: archived_branch ? module_archive_experiment_path(experiment) : my_modules_experiment_path(experiment),
        archived: archived_branch
      }
    )
  end

  def include_my_module(my_module)
    archived_branch = my_module.archived_branch?
    @breadcrumbs_items.push(
      {
        label: my_module.name,
        url: my_module_path(my_module),
        archived: archived_branch
      }
    )
  end
end
