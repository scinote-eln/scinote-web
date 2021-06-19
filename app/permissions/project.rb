# frozen_string_literal: true

Canaid::Permissions.register_for(Project) do
  include PermissionExtends

  # Project must be active for all the specified permissions
  %i(manage_project
     archive_project
     create_experiments
     create_comments_in_project
     manage_tags
     manage_project_access)
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
  # project: read, read activities, read comments, read users, read archive,
  #          read notifications
  # reports: read
  can :read_project do |_, _|
    # Already checked by the wrapper
    true
  end

  # team: export projects
  can :export_project do |_, _|
    # Already checked by the wrapper
    true
  end

  # project: update/delete, assign/reassign/unassign users
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

  # project: manage access policies
  can :manage_project_access do |user, project|
    project.permission_granted?(user, ProjectPermissions::MANAGE_ACCESS)
  end

  # project: archive
  can :archive_project do |user, project|
    project.permission_granted?(user, ProjectPermissions::ARCHIVE)
  end

  # NOTE: Must not be dependent on canaid parmision for which we check if it's
  # active
  # project: restore
  can :restore_project do |user, project|
    project.archived? && project.permission_granted?(user, ProjectPermissions::RESTORE)
  end

  # experiment: create

  can :create_experiments do |user, project|
    project.permission_granted?(user, ProjectPermissions::CREATE_EXPERIMENTS)
  end

  can :manage_experiments do |user, project|
    project.permission_granted?(user, ProjectPermissions::CREATE_EXPERIMENTS)
  end

  # project: create comment
  can :create_comments_in_project do |user, project|
    project.permission_granted?(user, ProjectPermissions::CREATE_COMMENTS)
  end

  # project: create/update/delete tag
  # module: assign/reassign/unassign tag
  can :manage_tags do |user, project|
    project.permission_granted?(user, ProjectPermissions::MANAGE_TAGS)
  end
end

Canaid::Permissions.register_for(ProjectComment) do
  # Project must be active for all the specified permissions
  %i(manage_comment_in_project)
    .each do |perm|
    can perm do |_, project_comment|
      project_comment.project.active?
    end
  end

  # project: update/delete comment
  can :manage_comment_in_project do |user, project_comment|
    project_comment.project.present? && (project_comment.user == user ||
      project.permission_granted?(user, ProjectPermissions::MANAGE_COMMENTS))
  end
end

Canaid::Permissions.register_for(ProjectFolder) do
  # ProjectFolder: delete
  can :delete_project_folder do |_, project_folder|
    !project_folder.projects.exists? && !project_folder.project_folders.exists?
  end
end
