# frozen_string_literal: true

Canaid::Permissions.register_for(Project) do
  include PermissionExtends

  # Project must be active for all the specified permissions
  %i(manage_project
     archive_project
     create_project_experiments
     create_project_comments
     manage_project_tags
     manage_project_users)
    .each do |perm|
    can perm do |_, project|
      project.active?
    end
  end

  %i(read_project
     export_project)
    .each do |perm|
    can perm do |user, project|
      project.permission_granted?(user, ProjectPermissions::READ)
    end
  end

  can :manage_project do |user, project|
    project.permission_granted?(user, ProjectPermissions::MANAGE) &&
      MyModule.joins(experiment: :project)
              .where(experiments: { project: project })
              .preload(my_module_status: :my_module_status_implications)
              .all? do |my_module|
        if my_module.my_module_status
          my_module.my_module_status.my_module_status_implications.all? { |implication| implication.call(my_module) }
        else
          true
        end
      end
  end

  can :read_project_folders do |user, project|
    project.permission_granted?(user, ProjectPermissions::FOLDERS_READ)
  end

  can :manage_project_users do |user, project|
    project.permission_granted?(user, ProjectPermissions::USERS_MANAGE)
  end

  can :archive_project do |user, project|
    project.permission_granted?(user, ProjectPermissions::MANAGE)
  end

  can :restore_project do |user, project|
    project.archived? && project.permission_granted?(user, ProjectPermissions::MANAGE)
  end

  can :create_project_experiments do |user, project|
    project.permission_granted?(user, ProjectPermissions::EXPERIMENTS_CREATE)
  end

  can :read_project_experiments do |user, project|
    project.permission_granted?(user, ProjectPermissions::EXPERIMENTS_READ)
  end

  can :read_archived_project_experiments do |user, project|
    project.permission_granted?(user, ProjectPermissions::EXPERIMENTS_READ_ARCHIVED)
  end

  can :read_canvas_of_project_experiments do |user, project|
    project.permission_granted?(user, ProjectPermissions::EXPERIMENTS_READ_CANVAS)
  end

  can :read_activities_of_project_experiments do |user, project|
    project.permission_granted?(user, ProjectPermissions::EXPERIMENTS_ACTIVITIES_READ)
  end

  can :read_users_of_project_experiments do |user, project|
    project.permission_granted?(user, ProjectPermissions::EXPERIMENTS_USERS_READ)
  end

  can :create_project_comments do |user, project|
    project.permission_granted?(user, ProjectPermissions::COMMENTS_CREATE)
  end

  can :manage_project_comments do |user, project|
    project.permission_granted?(user, ProjectPermissions::COMMENTS_MANAGE)
  end

  can :manage_project_tags do |user, project|
    project.permission_granted?(user, ProjectPermissions::MANAGE)
  end
end
