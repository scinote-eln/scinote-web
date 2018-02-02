Canaid::Permissions.register_for(Experiment) do
  # experiment: read
  # canvas/workflow: read
  can :read_experiment do |user, experiment|
    # TODO: When rebasing on top of refactored projects permissions, just call
    # can_read_project?(user, experiment.project) instead
    user.is_member_of_project?(experiment.project) ||
      user.is_admin_of_team?(experiment.project.team) ||
      (experiment.project.visible? &&
        user.is_member_of_team?(experiment.project.team))
  end

  # experiment: create, update, delete
  # canvas/workflow: edit
  # module: create, edit, delete, archive, move
  can :manage_experiment do |user, experiment|
    user.is_user_or_higher_of_project?(experiment.project)
  end

  can :restore_experiment do |user, experiment|
    experiment.archived? && can_manage_experiment?(user, experiment)
  end

  can :move_or_clone_experiment do |user, experiment|
    user.is_user_or_higher_of_project?(experiment.project) &&
      user.is_normal_user_or_admin_of_team?(experiment.project.team)
  end
end

Canaid::Permissions.register_for(MyModule) do
  can :restore_module do |user, my_module|
    my_module.archived? && can_manage_experiment?(user, experiment)
  end
end

Canaid::Permissions.register_for(Protocol) do
  # protocol: read
  # step: read, read comments, read assets, download assets
  can :read_protocol_in_module do |user, protocol|
    if protocol.in_module?
      my_module = protocol.my_module
      my_module.active? &&
        my_module.experiment.active? &&
        my_module.experiment.project.active? &&
        can_read_experiment?(user, my_module.experiment)
    else
      false
    end
  end

  # protocol: create, update, delete, unlink, revert, update from protocol in
  # repository
  # step: create, update, delete, reorder
  can :manage_protocol_in_module do |user, protocol|
    if protocol.in_module?
      my_module = protocol.my_module
      my_module.active? &&
        my_module.experiment.active? &&
        my_module.experiment.project.active? &&
        can_manage_experiment?(user, my_module.experiment)
    else
      false
    end
  end
end
