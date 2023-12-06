# frozen_string_literal: true

module Navigator
  class BaseController < ApplicationController
    private

    def project_serializer(project, archived)
      {
        id: project.code,
        name: project.name,
        url: experiments_path(project_id: project, view_mode: archived ? 'archived' : 'active'),
        archived: project.archived,
        type: :project,
        has_children: project.has_children,
        children_url: navigator_project_path(project),
        disabled: project.disabled
      }
    end

    def folder_serializer(folder, archived)
      {
        id: folder.code,
        name: folder.name,
        url: project_folder_path(folder, view_mode: archived ? 'archived' : 'active'),
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

    def my_module_serializer(my_module, archived)
      {
        id: my_module.code,
        name: my_module.name,
        type: :my_module,
        url: protocols_my_module_path(my_module, view_mode: archived ? 'archived' : 'active'),
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
      disabled_sql = 'SUM(CASE WHEN project_user_roles IS NULL THEN 0 ELSE 1 END) < 1 AS disabled'

      current_team.projects
                  .where(project_folder_id: folder)
                  .visible_to(current_user, current_team)
                  .with_children_viewable_by_user(current_user)
                  .joins("LEFT OUTER JOIN user_assignments project_user_assignments
                            ON project_user_assignments.assignable_type = 'Project'
                            AND project_user_assignments.assignable_id = projects.id
                            AND project_user_assignments.user_id = #{current_user.id}
                          LEFT OUTER JOIN user_roles project_user_roles
                            ON project_user_roles.id = project_user_assignments.user_role_id
                            AND project_user_roles.permissions @> ARRAY['#{ProjectPermissions::READ}']::varchar[]")
                  .where('projects.archived = :archived OR
                          (
                            (
                              experiments.archived = :archived OR
                              my_modules.archived = :archived
                            ) AND
                            :archived IS TRUE
                          ) OR
                          projects.id = :project_id',
                         archived: archived,
                         project_id: project&.id || -1)
                  .select(
                    'projects.id',
                    'projects.name',
                    'projects.archived',
                    disabled_sql,
                    has_children_sql
                  ).group('projects.id')
    end

    def fetch_project_folders(object = nil, archived = false)
      folder = if object.is_a?(ProjectFolder)
                 object
               else
                 object&.project_folder
               end
      has_children_sql = 'SUM(CASE WHEN viewable_projects.id IS NOT NULL OR project_folders_project_folders.id IS NOT NULL
      THEN 1 ELSE 0 END) > 0'
      current_team.project_folders.where(parent_folder: folder)
                  .left_outer_joins(:projects, project_folders: {})
                  .joins(
                    "LEFT OUTER JOIN (#{Project.viewable_by_user(current_user, current_team).where(archived: archived).to_sql}) " \
                    "viewable_projects ON viewable_projects.project_folder_id = project_folders.id"
                  )
                  .select(
                    'project_folders.id',
                    'project_folders.name',
                    'project_folders.archived',
                    "#{has_children_sql} AS has_children"
                  ).group('project_folders.id')
                  .having("project_folders.archived = :archived OR #{has_children_sql}", archived: archived)
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
                         elsif project.archived?
                           'COUNT(my_modules.id) > 0 AS has_children'
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

    def build_folder_tree(folder, children)
      archived = params[:archived] == 'true'
      tree = fetch_projects(folder.parent_folder, archived).map { |i| project_serializer(i, archived) } +
             fetch_project_folders(folder.parent_folder, archived).map { |i| folder_serializer(i, archived) }
      tree.find { |i| i[:id] == folder.code }[:children] = children
      tree = build_folder_tree(folder.parent_folder, tree) if folder.parent_folder.present?
      tree
    end

    def project_level_branch(object = nil)
      archived = params[:archived] == 'true'
      fetch_projects(object, archived)
        .map { |i| project_serializer(i, archived) } +
        fetch_project_folders(object, archived)
        .map { |i| folder_serializer(i, archived) }
    end

    def experiment_level_branch(object)
      archived = params[:archived] == 'true'
      fetch_experiments(object, archived)
        .map { |i| experiment_serializer(i, archived) }
    end

    def my_module_level_branch(experiment)
      archived = params[:archived] == 'true'
      fetch_my_modules(experiment, archived)
        .map { |i| my_module_serializer(i, archived) }
    end
  end
end
