# frozen_string_literal: true

Canaid::Permissions.register_for(MyModule) do
  # Module, its experiment and its project must be active for all the specified
  # permissions
  %i(manage_my_module
     manage_my_module_users
     assign_my_module_repository_rows
     create_my_module_comments
     create_my_module_repository_snapshots
     manage_my_module_repository_snapshots
     update_my_module_status)
    .each do |perm|
    can perm do |_, my_module|
      my_module.active? &&
        !my_module.status_changing? &&
        my_module.experiment.active? &&
        my_module.experiment.project.active?
    end
  end

  can :read_my_module do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::READ)
  end

  can :manage_my_module do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::MANAGE)
  end

  can :restore_my_module do |user, my_module|
    my_module.archived? && my_module.permission_granted?(user, MyModulePermissions::MANAGE)
  end

  can :archive_my_module do |user, my_module|
    !my_module.archived? && my_module.permission_granted?(user, MyModulePermissions::MANAGE)
  end

  can :update_my_module_start_date do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::MANAGE)
  end

  can :update_my_module_due_date do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::MANAGE)
  end

  can :update_my_module_notes do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::MANAGE)
  end

  can :manage_my_module_tags do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::TAGS_MANAGE)
  end

  can :manage_my_module_steps do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::STEPS_MANAGE)
  end

  can :create_my_module_comments do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::COMMENTS_CREATE)
  end

  can :assign_my_module_repository_rows do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::REPOSITORY_ROWS_ASSIGN)
  end

  can :manage_my_module_repository_rows do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::REPOSITORY_ROWS_MANAGE)
  end

  can :create_results do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::RESULTS_MANAGE)
  end

  can :create_my_module_result_comments do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::RESULTS_COMMENTS_CREATE)
  end

  can :manage_my_module_protocol do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::PROTOCOL_MANAGE)
  end

  can :complete_my_module do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::COMPLETE)
  end

  can :update_my_module_status do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::UPDATE_STATUS)
  end

  can :complete_my_module_steps do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::STEPS_COMPLETE)
  end

  can :uncomplete_my_module_steps do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::STEPS_UNCOMPLETE)
  end

  can :check_my_module_steps do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::STEPS_CHECKLIST_CHECK)
  end

  can :uncheck_my_module_steps do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::STEPS_CHECKLIST_UNCHECK)
  end

  can :create_comments_in_my_module_steps do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::STEPS_COMMENTS_CREATE)
  end

  can :delete_comments_in_my_module_steps do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::STEPS_COMMENTS_DELETE)
  end

  can :delete_own_comments_in_my_module_steps do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::STEPS_COMMENTS_DELETE_OWN)
  end

  can :update_comments_in_my_module_steps do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::STEPS_COMMENTS_UPDATE)
  end

  can :update_own_comments_in_my_module_steps do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::STEPS_COMMENT_UPDATE_OWN)
  end

  can :manage_my_module_users do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::MANAGE)
  end

  can :restore_my_module do |user, my_module|
    my_module.archived? && my_module.permission_granted?(user, MyModulePermissions::MANAGE)
  end

  can :create_my_module_repository_snapshots do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::REPOSITORY_ROWS_MANAGE)
  end

  can :manage_my_module_repository_snapshots do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::REPOSITORY_ROWS_MANAGE)
  end
end

Canaid::Permissions.register_for(TaskComment) do
  # Module, its experiment and its project must be active for all the specified
  # permissions
  %i(manage_my_module_comment)
    .each do |perm|
    can perm do |_, comment|
      my_module = ::PermissionsUtil.get_comment_module(comment)
      my_module.active? &&
        my_module.experiment.active? &&
        my_module.experiment.project.active?
    end
  end

  can :manage_my_module_comment do |user, comment|
    my_module = ::PermissionsUtil.get_comment_module(comment)
    my_module.permission_granted?(user, MyModulePermissions::COMMENTS_MANAGE) ||
      ((comment.user == user) && my_module.permission_granted?(user, MyModulePermissions::COMMENTS_MANAGE_OWN))
  end
end
