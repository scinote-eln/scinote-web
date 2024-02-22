Canaid::Permissions.register_for(Experiment) do
  # Experiment and its project must be active for all the specified permissions
  %i(manage_experiment
     create_experiment_tasks
     manage_experiment_users
     archive_experiment
     clone_experiment)
    .each do |perm|
    can perm do |_, experiment|
      experiment.active? &&
        experiment.project.active?
    end
  end

  # experiment: create/update/delete
  # canvas: update
  # module: create, copy, reposition, create/update/delete connection,
  #         assign/reassign/unassign tags
  can :manage_experiment do |user, experiment|
    next false unless experiment.permission_granted?(user, ExperimentPermissions::MANAGE)

    my_modules = experiment.my_modules
    unless experiment.association(:my_modules).loaded?
      my_modules = my_modules.preload(my_module_status: :my_module_status_implications)
    end

    my_modules.all? do |my_module|
      if my_module.my_module_status
        my_module.my_module_status.my_module_status_implications.all? { |implication| implication.call(my_module) }
      else
        true
      end
    end
  end

  can :read_experiment do |user, experiment|
    experiment.permission_granted?(user, ExperimentPermissions::READ)
  end

  can :read_archived_experiment do |user, experiment|
    experiment.permission_granted?(user, ExperimentPermissions::READ_ARCHIVED)
  end

  can :read_experiment_canvas do |user, experiment|
    experiment.permission_granted?(user, ExperimentPermissions::READ_CANVAS)
  end

  can :read_experiment_activities do |user, experiment|
    experiment.permission_granted?(user, ExperimentPermissions::ACTIVITIES_READ)
  end

  can :read_experiment_users do |user, experiment|
    experiment.permission_granted?(user, ExperimentPermissions::USERS_READ)
  end

  can :manage_experiment_users do |user, experiment|
    experiment.permission_granted?(user, ExperimentPermissions::USERS_MANAGE)
  end

  can :create_experiment_tasks do |user, experiment|
    experiment.permission_granted?(user, ExperimentPermissions::TASKS_CREATE)
  end

  can :manage_all_experiment_my_modules do |user, experiment|
    experiment.my_modules.where.not(id: experiment.my_modules.with_user_permission(user,
                                                                                   MyModulePermissions::MANAGE)).none?
  end

  can :archive_experiment do |user, experiment|
    experiment.permission_granted?(user, ExperimentPermissions::MANAGE)
  end

  can :restore_experiment do |user, experiment|
    project = experiment.project
    experiment.permission_granted?(user, ExperimentPermissions::MANAGE) &&
      experiment.archived? &&
      project.active?
  end

  can :clone_experiment do |user, experiment|
    experiment.permission_granted?(user, ExperimentPermissions::READ)
  end

  can :move_experiment do |user, experiment|
    experiment.permission_granted?(user, ExperimentPermissions::MANAGE) &&
      can_manage_all_experiment_my_modules?(experiment)
  end

  can :designate_users_to_new_task do |user, experiment|
    experiment.permission_granted?(user, MyModulePermissions::DESIGNATED_USERS_MANAGE)
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
  %i(manage_protocol_in_module
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
    protocol.my_module.permission_granted?(user, MyModulePermissions::READ)
  end

  # protocol in module: create/update/delete, unlink, revert, update from
  # protocol in repository, update from file
  # step in module: create/update/delete, reorder
  can :manage_protocol_in_module do |user, protocol|
    can_manage_my_module_protocol?(user, protocol.my_module)
  end

  # step: complete/uncomplete
  can :complete_or_checkbox_step do |user, protocol|
    can_update_my_module_status?(user, protocol.my_module)
  end
end
