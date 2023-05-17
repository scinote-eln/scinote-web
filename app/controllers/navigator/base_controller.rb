# frozen_string_literal: true

module Navigator
  class BaseController < ApplicationController
    private

    def project_serializer(project, archived)
      {
        id: project.code,
        name: project.name,
        url: project_path(project, view_mode: archived ? 'archived' : 'active'),
        archived: project.archived,
        type: :project,
        has_children: project.has_children,
        children_url: navigator_project_path(project)
      }
    end

    def folder_serializer(folder, archived)
      {
        id: folder.code,
        name: folder.name,
        url: projects_path(project_folder_id: folder.id, view_mode: archived ? 'archived' : 'active'),
        archived: folder.archived,
        type: :folder,
        has_children: folder.has_children,
        children_url: navigator_project_folder_path(folder)
      }
    end

    def experiment_serializer(experiment, archived)
      {
        id: experiment.code,
        name: experiment.name,
        url: my_modules_experiment_path(experiment, view_mode: archived ? 'archived' : 'active'),
        archived: experiment.archived_branch?,
        type: :experiment,
        has_children: experiment.has_children,
        children_url: navigator_experiment_path(experiment)
      }
    end

    def my_module_serializer(my_module)
      {
        id: my_module.code,
        name: my_module.name,
        type: :my_module,
        url: protocols_my_module_path(my_module),
        archived: my_module.archived_branch?,
        has_children: false
      }
    end

    def fetch_projects(object = nil, archived = false)
      if object&.is_a?(ProjectFolder)
        folder = object
        project = nil
      else
        folder = object&.project_folder
        project = object
      end
      has_children_sql = if !archived
                           'SUM(CASE WHEN experiments.archived IS FALSE OR
                                          (projects.archived IS TRUE AND experiments.id IS  NOT NULL)
                                     THEN 1 ELSE 0 END) > 0 AS has_children'
                         else
                           'SUM(CASE WHEN experiments.archived IS TRUE OR
                                          my_modules.archived IS TRUE OR
                                          (projects.archived IS TRUE AND experiments.id IS  NOT NULL)
                                     THEN 1 ELSE 0 END) > 0 AS has_children'
                         end
      current_team.projects
                  .where(project_folder_id: folder)
                  .visible_to(current_user, current_team)
                  .with_children_viewable_by_user(current_user)
                  .where('
                    projects.archived = :archived OR
                    (
                      (
                        experiments.archived = :archived OR
                        my_modules.archived = :archived
                      ) AND
                      :archived IS TRUE
                    ) OR
                    projects.id = :project_id
                  ', archived: archived, project_id: project&.id || -1)
                  .select(
                    'projects.id',
                    'projects.name',
                    'projects.archived',
                    has_children_sql
                  ).group('projects.id')
    end

    def fetch_project_folders(object = nil, archived = false)
      folder = if object&.is_a?(ProjectFolder)
                 object
               else
                 object&.project_folder
               end
      current_team.project_folders.where(parent_folder: folder)
                  .left_outer_joins(projects: { user_assignments: :user_role }, project_folders: {})
                  .where(project_folders: { archived: archived })
                  .where('
                    user_assignments.user_id = ? AND
                    user_roles.permissions @> ARRAY[?]::varchar[] OR
                    projects.id IS NULL
                  ', current_user.id, ProjectPermissions::READ)
                  .select(
                    'project_folders.id',
                    'project_folders.name',
                    'project_folders.archived',
                    'SUM(CASE WHEN projects.id IS NOT NULL OR project_folders_project_folders.id IS NOT NULL
                              THEN 1 ELSE 0 END) > 0 AS has_children'
                  ).group('project_folders.id')
    end

    def fetch_experiments(object, archived = false)
      if object.is_a?(Project)
        project = object
        experiment = nil
      else
        project = object.project
        experiment = object
      end

      has_children_sql = if !archived
                           'SUM(CASE WHEN my_modules.archived IS FALSE OR
                                          (experiments.archived IS TRUE AND my_modules.id IS NOT NULL)
                                     THEN 1 ELSE 0 END) > 0 AS has_children'
                         else
                           'SUM(CASE WHEN my_modules.archived IS TRUE OR
                                          (experiments.archived IS TRUE AND my_modules.id IS NOT NULL)
                                     THEN 1 ELSE 0 END) > 0 AS has_children'
                         end
      experiments = project.experiments
                           .viewable_by_user(current_user, current_team)
                           .with_children_viewable_by_user(current_user)
                           .select(
                             'experiments.id',
                             'experiments.name',
                             'experiments.archived',
                             'experiments.project_id',
                             has_children_sql
                           ).group('experiments.id')
      unless project.archived?
        experiments = experiments.where('
            experiments.archived = :archived OR
            my_modules.archived = :archived AND
            :archived IS TRUE OR
            experiments.id = :experiment_id
          ', archived: archived, experiment_id: experiment&.id || -1)
      end

      experiments
    end

    def fetch_my_modules(experiment, archived = false)
      my_modules = experiment.my_modules
                             .viewable_by_user(current_user, current_team)
      my_modules = my_modules.where(archived: archived) unless experiment.archived_branch?

      my_modules
    end

    def build_folder_tree(folder, children, archived = false)
      tree = fetch_projects(folder.parent_folder, archived).map { |i| project_serializer(i, archived) } +
             fetch_project_folders(folder.parent_folder, archived).map { |i| folder_serializer(i, archived) }
      tree.find { |i| i[:id] == folder.code }[:children] = children
      tree = build_folder_tree(folder.parent_folder, tree, archived) if folder.parent_folder.present?
      tree
    end

    def project_level_branch(object = nil, archived = false)
      fetch_projects(object, archived)
        .map { |i| project_serializer(i, archived) } +
        fetch_project_folders(object, archived)
        .map { |i| folder_serializer(i, archived) }
    end

    def experiment_level_branch(object, archived = false)
      fetch_experiments(object, archived)
        .map { |i| experiment_serializer(i, archived) }
    end

    def my_module_level_branch(experiment, archived = false)
      fetch_my_modules(experiment, archived)
        .map { |i| my_module_serializer(i) }
    end
  end
end
