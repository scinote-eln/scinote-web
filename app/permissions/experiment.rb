Canaid::Permissions.register_for(Experiment) do
  # experiment: read (read archive)
  # canvas: read
  # module: read (read users, read comments, read archive)
  # result: read (read comments)
  can :read_experiment do |user, experiment|
    can_read_project?(user, experiment.project)
  end

  # experiment: create, update, delete
  # canvas: edit
  # module: create, clone, reposition, create/update/delete connection,
  #         assign/reassign/unassign tags
  can :manage_experiment do |user, experiment|
    user.is_user_or_higher_of_project?(experiment.project)
  end

  # experiment: archive
  can :archive_experiment do |user, experiment|
    can_manage_experiment?(user, experiment)
  end

  # experiment: restore
  can :restore_experiment do |user, experiment|
    can_manage_experiment?(user, experiment) && experiment.archived?
  end

  # experiment: clone
  can :clone_experiment do |user, experiment|
    user.is_user_or_higher_of_project?(experiment.project) &&
      user.is_normal_user_or_admin_of_team?(experiment.project.team)
  end

  # experiment: move
  can :move_experiment do |user, experiment|
    can_clone_experiment?(user, experiment)
  end

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
end

Canaid::Permissions.register_for(MyModule) do
  # module: edit, archive, move
  # result: create, update
  can :manage_module do |user, my_module|
    can_manage_experiment?(user, my_module.experiment)
  end

  # module: restore
  can :restore_module do |user, my_module|
    can_manage_experiment?(user, my_module.experiment) && my_module.archived?
  end

  # module: assign/reassign/unassign users
  can :manage_users_in_module do |user, my_module|
    user.is_owner_of_project?(my_module.experiment.project)
  end

  # result: delete, archive
  can :delete_or_archive_result do |user, my_module|
    user.is_owner_of_project?(my_module.experiment.project)
  end

  # module: assign/unassign sample, assign/unassign repository record
  # NOTE: Use 'module_page? &&' before calling this permission!
  can :assign_repository_records_to_module do |user, my_module|
    user.is_technician_or_higher_of_project?(my_module.experiment.project)
  end

  # module: complete/uncomplete
  can :complete_module do |user, my_module|
    user.is_technician_or_higher_of_project?(my_module.experiment.project)
  end

  # TODO: When rebasing on top of refactored projects permissions, just call
  # can_create_comment_in_project?(user, my_module.experiment.project) instead
  # module: create comment
  # result: create comment
  # step: create comment
  can :create_comment_in_module do |user, my_module|
    user.is_technician_or_higher_of_project?(my_module.experiment.project)
  end

  %i(manage_module
     manage_users_in_module
     delete_or_archive_result
     assign_sample_to_module
     complete_module
     create_comment_in_module).each do |perm|
    can perm do |_, my_module|
      my_module.active? &&
        my_module.experiment.active? &&
        my_module.experiment.project.active?
    end
  end
end

Canaid::Permissions.register_for(Protocol) do
  # protocol in module: read
  # step: read, read comments, read assets, download assets
  can :read_protocol_in_module do |user, protocol|
    if protocol.in_module?
      can_read_experiment?(user, protocol.my_module.experiment)
    else
      false
    end
  end

  # protocol in module: create/update/delete, unlink, revert, update from
  # protocol in repository, update from file
  # step: create/update/delete, reorder
  can :manage_protocol_in_module do |user, protocol|
    if protocol.in_module?
      can_manage_module?(user, protocol.my_module)
    else
      false
    end
  end

  # step: complete/uncomplete
  can :complete_or_checkbox_step do |user, protocol|
    if protocol.in_module?
      can_complete_module?(user, protocol.my_module)
    else
      # In repository, user cannot complete steps
      false
    end
  end

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
end

Canaid::Permissions.register_for(Comment) do
  # module: update/delete comment
  # result: update/delete comment
  # step: update/delete comment
  can :manage_comment_in_module do |user, comment|
    project = case comment.is_a?
              when TaskComment
                comment.my_module.experiment.project
              when ResultComment
                comment.result.my_module.experiment.project
              when StepComment
                comment.step.protocol.my_module.experiment.project
              end
    project.present? &&
      # TODO: When rebasing on top of refactored projects permissions, just call
      # can_manage_comment_in_project?(user, project) instead
      (user.is_owner_of_project(project) || comment.user == current_user)
  end

  %i(comment).each do |perm|
    can perm do |_, comment|
      my_module = case comment.is_a?
                  when TaskComment
                    comment.my_module
                  when ResultComment
                    comment.result.my_module
                  when StepComment
                    comment.step.protocol.my_module
                  end
      my_module.active? &&
        my_module.experiment.active? &&
        my_module.experiment.project.active?
    end
  end
end
