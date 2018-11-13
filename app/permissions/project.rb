Canaid::Permissions.register_for(Project) do
  # Project must be active for all the specified permissions
  %i(read_project
     manage_project
     archive_project
     create_experiments
     create_comments_in_project
     manage_tags)
    .each do |perm|
    can perm do |_, project|
      project.active?
    end
  end

  %i(read_project
     export_project)
    .each do |perm|
    can perm do |user, project|
      user.is_member_of_project?(project) ||
        user.is_admin_of_team?(project.team) ||
        (project.visible? && user.is_member_of_team?(project.team))
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
    user.is_owner_of_project?(project)
  end

  # project: archive
  can :archive_project do |user, project|
    can_manage_project?(user, project)
  end

  # NOTE: Must not be dependent on canaid parmision for which we check if it's
  # active
  # project: restore
  can :restore_project do |user, project|
    user.is_owner_of_project?(project) && project.archived?
  end

  # experiment: create
  can :create_experiments do |user, project|
    user.is_user_or_higher_of_project?(project)
  end

  # project: create comment
  can :create_comments_in_project do |user, project|
    user.is_technician_or_higher_of_project?(project)
  end

  # project: create/update/delete tag
  # module: assign/reassign/unassign tag
  can :manage_tags do |user, project|
    user.is_user_or_higher_of_project?(project)
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
      user.is_owner_of_project?(project_comment.project))
  end
end
