Canaid::Permissions.register_for(Experiment) do
  # experiment: read
  # canvas/workflow: read
  can :read_experiment do |user, experiment|
    can_read_project?(user, experiment.project)
  end

  # experiment: create/update/delete
  # canvas/workflow: edit
  # module: create
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
      experiment.project.active?
    end
  end
end

Canaid::Permissions.register_for(MyModule) do
  # module: restore
  can :restore_module do |user, my_module|
    can_manage_experiment?(user, my_module.experiment) && my_module.archived?
  end

  # module: edit, archive, move
  can :manage_module do |user, my_module|
    can_manage_experiment?(user, my_module.experiment)
  end

  %i(manage_module).each do |perm|
    can perm do |_, my_module|
      my_module.experiment.project.active?
    end
  end
end

Canaid::Permissions.register_for(Protocol) do
  # protocol in module: read
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

  # protocol in module: create/update/delete, unlink, revert, update from
  # protocol in repository, update from file
  # step: create/update/delete, reorder
  can :manage_protocol_in_module do |user, protocol|
    if protocol.in_module?
      my_module = protocol.my_module
      my_module.active? &&
        my_module.experiment.active? &&
        my_module.experiment.project.active? &&
        can_manage_module?(user, my_module)
    else
      false
    end
  end

  %i(read_protocol_in_module
     manage_protocol_in_module)
    .each do |perm|
    can perm do |_, protocol|
      protocol.my_module.experiment.project.active?
    end
  end
end
