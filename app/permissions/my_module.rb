# frozen_string_literal: true

Canaid::Permissions.register_for(MyModule) do
  # Module, its experiment and its project must be active for all the specified
  # permissions
  %i(manage_module
     archive_module
     manage_users_in_module
     assign_repository_rows_to_module
     create_comments_in_module
     create_my_module_repository_snapshot
     manage_my_module_repository_snapshots
     change_my_module_flow_status
     manage_module_access)
    .each do |perm|
    can perm do |_, my_module|
      my_module.active? &&
        !my_module.status_changing? &&
        my_module.experiment.active? &&
        my_module.experiment.project.active?
    end
  end

  # module: update
  # result: create, update
  can :manage_module do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::MANAGE)
  end

  # module: archive
  can :archive_module do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::ARCHIVE)
  end

  # module: manage access policies
  can :manage_module_access do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::MANAGE_ACCESS)
  end

  # NOTE: Must not be dependent on canaid parmision for which we check if it's
  # active
  # module: restore
  can :restore_module do |user, my_module|
    my_module.archived? && my_module.permission_granted?(user, MyModulePermissions::RESTORE)
  end

  # module: move
  can :move_module do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::MOVE)
  end

  # module: read
  can :read_module do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::READ)
  end

  # module: assign/reassign/unassign users
  can :manage_users_in_module do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::MANAGE_USERS)
  end

  # module: assign/unassign repository record
  # NOTE: Use 'module_page? &&' before calling this permission!
  can :assign_repository_rows_to_module do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::ASSIGN_REPOSITORY_ROWS)
  end

  # module: change_flow_status
  can :change_my_module_flow_status do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::CHANGE_FLOW_STATUS)
  end

  # module: create comment
  # result: create comment
  # step: create comment
  can :create_comments_in_module do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::CREATE_COMMENTS)
  end

  # module: create a snapshot of repository item
  can :create_my_module_repository_snapshot do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::CREATE_REPOSITORY_SNAPSHOT)
  end

  # module: make a repository snapshot selected
  can :manage_my_module_repository_snapshots do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::MANAGE_REPOSITORY_SNAPSHOT)
  end
end
