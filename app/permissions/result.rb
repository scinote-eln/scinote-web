# frozen_string_literal: true

Canaid::Permissions.register_for(Result) do
  can :read_result do |user, result|
    can_read_my_module?(user, result.my_module)
  end

  can :manage_result do |user, result|
    !result.archived? &&
      !result.my_module.archived_branch? &&
      result.my_module.permission_granted?(user, MyModulePermissions::RESULTS_MANAGE)
  end

  can :restore_result do |user, result|
    result.archived? &&
      !result.my_module.archived_branch? &&
      result.my_module.permission_granted?(user, MyModulePermissions::RESULTS_MANAGE)
  end

  can :delete_result do |user, result|
    result.archived? &&
      !result.my_module.archived_branch? &&
      result.unlocked?(result) &&
      result.my_module.permission_granted?(user, MyModulePermissions::RESULTS_DELETE_ARCHIVED)
  end
end

Canaid::Permissions.register_for(ResultComment) do
  # Module, its experiment and its project must be active for all the specified
  # permissions
  %i(manage_result_comment)
    .each do |perm|
    can perm do |_, comment|
      !comment.result.my_module.archived_branch? && comment.result.active?
    end
  end

  # module: update/delete comment
  # result: update/delete comment
  # step: update/delete comment
  can :manage_result_comment do |user, comment|
    my_module = comment.result.my_module
    (comment.user == user && my_module.permission_granted?(user, MyModulePermissions::RESULTS_COMMENTS_MANAGE_OWN)) ||
      my_module.permission_granted?(user, MyModulePermissions::RESULTS_COMMENTS_MANAGE)
  end
end
