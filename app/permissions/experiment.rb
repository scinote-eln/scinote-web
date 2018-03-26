Canaid::Permissions.register_for(Experiment) do
  # Experiment and its project must be active for all the specified permissions
  %i(read_experiment
     manage_experiment
     archive_experiment
     clone_experiment
     move_experiment)
    .each do |perm|
    can perm do |_, experiment|
      experiment.active? &&
        experiment.project.active?
    end
  end

  # experiment: read (read archive)
  # canvas: read
  # module: read (read users, read comments, read archive)
  # result: read (read comments)
  can :read_experiment do |user, experiment|
    can_read_project?(user, experiment.project)
  end

  # experiment: create/update/delete
  # canvas: update
  # module: create, copy, reposition, create/update/delete connection,
  #         assign/reassign/unassign tags
  can :manage_experiment do |user, experiment|
    user.is_user_or_higher_of_project?(experiment.project)
  end

  # experiment: archive
  can :archive_experiment do |user, experiment|
    can_manage_experiment?(user, experiment)
  end

  # NOTE: Must not be dependent on canaid parmision for which we check if it's
  # active
  # experiment: restore
  can :restore_experiment do |user, experiment|
    user.is_user_or_higher_of_project?(experiment.project) &&
      experiment.archived?
  end

  # experiment: copy
  can :clone_experiment do |user, experiment|
    user.is_user_or_higher_of_project?(experiment.project) &&
      user.is_normal_user_or_admin_of_team?(experiment.project.team)
  end

  # experiment: move
  can :move_experiment do |user, experiment|
    can_clone_experiment?(user, experiment)
  end
end

Canaid::Permissions.register_for(MyModule) do
  # Module, its experiment and its project must be active for all the specified
  # permissions
  %i(manage_module
     manage_users_in_module
     assign_repository_rows_to_module
     assign_sample_to_module
     complete_module
     create_comments_in_module)
    .each do |perm|
    can perm do |_, my_module|
      my_module.active? &&
        my_module.experiment.active? &&
        my_module.experiment.project.active?
    end
  end

  # module: update, archive, move
  # result: create, update
  can :manage_module do |user, my_module|
    can_manage_experiment?(user, my_module.experiment)
  end

  # NOTE: Must not be dependent on canaid parmision for which we check if it's
  # active
  # module: restore
  can :restore_module do |user, my_module|
    user.is_user_or_higher_of_project?(my_module.experiment.project) &&
      my_module.archived?
  end

  # module: assign/reassign/unassign users
  can :manage_users_in_module do |user, my_module|
    user.is_owner_of_project?(my_module.experiment.project)
  end

  # module: assign/unassign repository record
  # NOTE: Use 'module_page? &&' before calling this permission!
  can :assign_repository_rows_to_module do |user, my_module|
    user.is_technician_or_higher_of_project?(my_module.experiment.project)
  end

  # module: assign/unassign sample
  # NOTE: Use 'module_page? &&' before calling this permission!
  can :assign_sample_to_module do |user, my_module|
    user.is_technician_or_higher_of_project?(my_module.experiment.project)
  end

  # module: complete/uncomplete
  can :complete_module do |user, my_module|
    user.is_technician_or_higher_of_project?(my_module.experiment.project)
  end

  # module: create comment
  # result: create comment
  # step: create comment
  can :create_comments_in_module do |user, my_module|
    can_create_comments_in_project?(user, my_module.experiment.project)
  end
end

Canaid::Permissions.register_for(Protocol) do
  # Protocol needs to be in a module for all Protocol permissions below
  # experiment level
  %i(read_protocol_in_module
     manage_protocol_in_module
     complete_or_checkbox_step)
    .each do |perm|
    can perm do |_, protocol|
      protocol.in_module?
    end
  end

  # Module, its experiment and its project must be active for all the specified
  # permissions
  %i(read_protocol_in_module
     manage_protocol_in_module
     complete_or_checkbox_step)
    .each do |perm|
    can perm do |_, protocol|
      my_module = protocol.my_module
      my_module.active? &&
        my_module.experiment.active? &&
        my_module.experiment.project.active?
    end
  end

  # protocol in module: read
  # step in module: read, read comments, read/download assets
  can :read_protocol_in_module do |user, protocol|
    can_read_experiment?(user, protocol.my_module.experiment)
  end

  # protocol in module: create/update/delete, unlink, revert, update from
  # protocol in repository, update from file
  # step in module: create/update/delete, reorder
  can :manage_protocol_in_module do |user, protocol|
    can_manage_module?(user, protocol.my_module)
  end

  # step: complete/uncomplete
  can :complete_or_checkbox_step do |user, protocol|
    can_complete_module?(user, protocol.my_module)
  end
end

Canaid::Permissions.register_for(Result) do
  # Module, its experiment and its project must be active for all the specified
  # permissions
  %i(manage_result).each do |perm|
    can perm do |_, result|
      my_module = result.my_module
      my_module.active? &&
        my_module.experiment.active? &&
        my_module.experiment.project.active?
    end
  end

  # result: delete, archive
  can :manage_result do |user, result|
    result.unlocked?(result) &&
      user.is_owner_of_project?(result.my_module.experiment.project)
  end
end

Canaid::Permissions.register_for(Comment) do
  # Module, its experiment and its project must be active for all the specified
  # permissions
  %i(manage_comment_in_module)
    .each do |perm|
    can perm do |_, comment|
      my_module = ::PermissionsUtil.get_comment_module(comment)
      my_module.active? &&
        my_module.experiment.active? &&
        my_module.experiment.project.active?
    end
  end

  # module: update/delete comment
  # result: update/delete comment
  # step: update/delete comment
  can :manage_comment_in_module do |user, comment|
    my_module = ::PermissionsUtil.get_comment_module(comment)
    project = my_module.experiment.project
    # Same check as in `can_manage_comment_in_project?`
    project.present? &&
      (user.is_owner_of_project?(project) || comment.user == user)
  end
end
