# frozen_string_literal: true

module Navigator
  class BaseController < ApplicationController
    private

    def project_serializer(project)
      {
        id: project.code,
        name: project.name,
        url: project_path(project),
        archived: project.archived,
        type: :project,
        has_children: project.has_children,
        children_url: navigator_project_path(project)
      }
    end

    def folder_serializer(folder)
      {
        id: folder.code,
        name: folder.name,
        url: projects_path(project_folder_id: folder.id),
        archived: folder.archived,
        type: :folder,
        has_children: folder.has_children,
        children_url: navigator_project_folder_path(folder)
      }
    end

    def experiment_serializer(experiment)
      {
        id: experiment.code,
        name: experiment.name,
        url: canvas_experiment_path(experiment),
        archived: experiment.archived,
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
        archived: my_module.archived,
        has_children: false
      }
    end

    def fetch_projects(folder = nil, archived = false)
      has_children_sql = if !archived
                           'SUM(CASE WHEN experiments.archived IS FALSE THEN 1 ELSE 0 END) > 0 AS has_children'
                         else
                           'SUM(CASE WHEN experiments.archived IS TRUE OR my_modules.archived IS TRUE
                                THEN 1 ELSE 0 END) > 0 AS has_children'
                         end
      current_team.projects
                  .where(project_folder_id: folder)
                  .viewable_by_user(current_user, current_team)
                  .with_children_viewable_by_user(current_user)
                  .where('
                    projects.archived = :archived OR
                    (
                      (
                        experiments.archived = :archived OR
                        my_modules.archived = :archived
                      ) AND
                      :archived IS TRUE
                    )
                  ', archived: archived)
                  .select(
                    'projects.id',
                    'projects.name',
                    'projects.archived',
                    has_children_sql
                  ).group('projects.id')
    end

    def fetch_project_folders(folder = nil, archived = false)
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

    def fetch_experiments(project, archived = false)
      has_children_sql = if !archived
                           'SUM(CASE WHEN my_modules.archived IS FALSE THEN 1 ELSE 0 END) > 0 AS has_children'
                         else
                           'SUM(CASE WHEN my_modules.archived IS TRUE THEN 1 ELSE 0 END) > 0 AS has_children'
                         end
      project.experiments
             .viewable_by_user(current_user, current_team)
             .with_children_viewable_by_user(current_user)
             .where('
              experiments.archived = :archived OR
              my_modules.archived = :archived AND
              :archived IS TRUE
            ', archived: archived)
             .select(
               'experiments.id',
               'experiments.name',
               'experiments.archived',
               has_children_sql
             ).group('experiments.id')
    end

    def fetch_my_modules(experiment, archived = false)
      experiment.my_modules
                .viewable_by_user(current_user, current_team)
                .where(archived: archived)
    end

    def build_folder_tree(folder, children, archived = false)
      parent_folder = folder.parent_folder
      tree = fetch_projects(parent_folder, archived).map { |i| project_serializer(i) } +
             fetch_project_folders(parent_folder, archived).map { |i| folder_serializer(i) }
      tree.find { |i| i[:id] == folder.code }[:children] = children
      tree = build_folder_tree(parent_folder, tree, archived) if parent_folder.present?
      tree
    end

    def project_level_branch(folder = nil, archived = false)
      fetch_projects(folder, archived)
        .map { |i| project_serializer(i) } +
        fetch_project_folders(folder, archived)
        .map { |i| folder_serializer(i) }
    end

    def experiment_level_branch(project, archived = false)
      fetch_experiments(project, archived)
        .map { |i| experiment_serializer(i) }
    end

    def my_module_level_branch(experiment, archived = false)
      fetch_my_modules(experiment, archived)
        .map { |i| my_module_serializer(i) }
    end
  end
end
