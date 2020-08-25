Canaid::Permissions.register_for(MyModule) do
  # Module, its experiment and its project must be active for all the specified
  # permissions
  %i(manage_module
     manage_users_in_module
     assign_repository_rows_to_module
     assign_sample_to_module
     create_comments_in_module
     create_my_module_repository_snapshot
     manage_my_module_repository_snapshots)
    .each do |perm|
    can perm do |_, my_module|
      my_module.active? &&
        my_module.experiment.active? &&
        my_module.experiment.project.active?
    end
  end

  # module: update
  # result: create, update
  can :manage_module do |user, my_module|
    can_manage_experiment?(user, my_module.experiment)
  end

  # module: archive
  can :archive_module do |user, my_module|
    can_manage_experiment?(user, my_module.experiment)
  end

  # NOTE: Must not be dependent on canaid parmision for which we check if it's
  # active
  # module: restore
  can :restore_module do |user, my_module|
    user.is_user_or_higher_of_project?(my_module.experiment.project) &&
      my_module.archived?
  end

  # module: move
  can :move_module do |user, my_module|
    can_manage_experiment?(user, my_module.experiment)
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

  # module: change_flow_status
  can :change_my_module_flow_status do |user, my_module|
    user.is_technician_or_higher_of_project?(my_module.experiment.project)
  end

  # module: create comment
  # result: create comment
  # step: create comment
  can :create_comments_in_module do |user, my_module|
    can_create_comments_in_project?(user, my_module.experiment.project)
  end

  # module: create a snapshot of repository item
  can :create_my_module_repository_snapshot do |user, my_module|
    user.is_technician_or_higher_of_project?(my_module.experiment.project)
  end

  # module: make a repository snapshot selected
  can :manage_my_module_repository_snapshots do |user, my_module|
    user.is_technician_or_higher_of_project?(my_module.experiment.project)
  end
end
