Canaid::Permissions.register_for(Project) do
  # project: read, read activities, read comments, read users, read archive,
  #          read notifications
  # reports: read
  # samples: read
  can :read_project do |user, project|
    user.is_member_of_project?(project) ||
      user.is_admin_of_team?(project.team) ||
      (project.visible? && user.is_member_of_team?(project.team))
  end

  # project: update/delete/archive, assign/reassign/unassign users
  can :manage_project do |user, project|
    user.is_owner_of_project?(project)
  end

  # project: archive
  can :archive_project do |user, project|
    can_manage_project?(user, project)
  end

  # project: restore
  can :restore_project do |user, project|
    can_manage_project?(user, project) && project.archived?
  end

  # experiment: create
  can :create_experiment do |user, project|
    user.is_user_or_higher_of_project?(project)
  end

  # project: create comment
  can :create_comment_in_project do |user, project|
    user.is_technician_or_higher_of_project?(project)
  end

  # project: create/update/delete tag
  # module: assign/reassign/unassign tag
  can :create_or_manage_tags do |user, project|
    user.is_user_or_higher_of_project?(project)
  end

  # reports: create/delete
  can :create_or_manage_reports do |user, project|
    user.is_technician_or_higher_of_project?(project)
  end

  # Project must be active for all the specified permissions
  %i(read_project
     manage_project
     archive_project
     create_experiment
     create_comment_in_project
     create_or_manage_tags
     create_or_manage_reports)
    .each do |perm|
    can perm do |_, project|
      project.active?
    end
  end
end

Canaid::Permissions.register_for(Comment) do
  # project: update/delete comment
  can :manage_comment_in_project do |user, comment|
    comment.project.present? && (comment.user == user ||
      user.is_owner_of_project?(project))
  end

  # Project must be active for all the specified permissions
  %i(manage_comment_in_project)
    .each do |perm|
    can perm do |_, comment|
      comment.project.active?
    end
  end
end
