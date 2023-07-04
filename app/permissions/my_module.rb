# frozen_string_literal: true

Canaid::Permissions.register_for(MyModule) do
  # Module, its experiment and its project must be active for all the specified
  # permissions
  %i(manage_my_module
     archive_my_module
     manage_my_module_protocol
     manage_my_module_users
     manage_my_module_designated_users
     assign_my_module_repository_rows
     manage_my_module_repository_rows
     create_results
     create_my_module_comments
     create_comments_in_my_module_steps
     create_my_module_result_comments
     create_my_module_repository_snapshots
     manage_my_module_repository_snapshots
     update_my_module_start_date
     update_my_module_due_date
     complete_my_module
     update_my_module_description
     manage_my_module_tags
     update_my_module_status
     manage_my_module_steps
     complete_my_module_steps
     uncomplete_my_module_steps
     check_my_module_steps
     uncheck_my_module_steps)
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

  can :share_my_module do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::SHARE)
  end

  can :restore_my_module do |user, my_module|
    my_module.archived? && my_module.permission_granted?(user, MyModulePermissions::MANAGE)
  end

  can :archive_my_module do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::MANAGE)
  end

  can :move_my_module do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::MANAGE)
  end

  can :update_my_module_start_date do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::UPDATE_START_DATE)
  end

  can :update_my_module_due_date do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::UPDATE_DUE_DATE)
  end

  can :update_my_module_description do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::UPDATE_DESCRIPTION)
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

  can :read_my_module_users do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::USERS_READ)
  end

  can :manage_my_module_users do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::USERS_MANAGE)
  end

  can :manage_my_module_designated_users do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::DESIGNATED_USERS_MANAGE)
  end

  can :read_my_module_activities do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::ACTIVITIES_READ)
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

  can :update_my_module_stock_consumption do |user, my_module|
    my_module.permission_granted?(user, MyModulePermissions::STOCK_CONSUMPTION_UPDATE) &&
      RepositoryBase.stock_management_enabled?
  end
end

Canaid::Permissions.register_for(TaskComment) do
  # Module, its experiment and its project must be active for all the specified
  # permissions
  %i(manage_my_module_comment)
    .each do |perm|
    can perm do |_, comment|
      my_module = comment.my_module
      my_module.active? &&
        my_module.experiment.active? &&
        my_module.experiment.project.active?
    end
  end

  can :manage_my_module_comment do |user, comment|
    my_module = comment.my_module
    my_module.permission_granted?(user, MyModulePermissions::COMMENTS_MANAGE) ||
      ((comment.user == user) && my_module.permission_granted?(user, MyModulePermissions::COMMENTS_MANAGE_OWN))
  end
end

Canaid::Permissions.register_for(StepComment) do
  # Module, its experiment and its project must be active for all the specified
  # permissions
  %i(delete_comment_in_my_module_steps
     update_comment_in_my_module_steps)
    .each do |perm|
    can perm do |_, comment|
      my_module = comment.step.my_module
      my_module.active? &&
        !my_module.archived_branch? &&
        my_module.experiment.active? &&
        my_module.experiment.project.active?
    end
  end

  can :delete_comment_in_my_module_steps do |user, comment|
    my_module = comment.step.my_module
    my_module.permission_granted?(user, MyModulePermissions::STEPS_COMMENTS_DELETE) ||
      ((comment.user == user) && my_module.permission_granted?(user, MyModulePermissions::STEPS_COMMENTS_DELETE_OWN))
  end

  can :update_comment_in_my_module_steps do |user, comment|
    my_module = comment.step.my_module
    my_module.permission_granted?(user, MyModulePermissions::STEPS_COMMENTS_UPDATE) ||
      ((comment.user == user) && my_module.permission_granted?(user, MyModulePermissions::STEPS_COMMENTS_UPDATE_OWN))
  end
end
