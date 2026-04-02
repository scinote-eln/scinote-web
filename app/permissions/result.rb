# frozen_string_literal: true

Canaid::Permissions.register_for(ResultBase) do
  can :read_result do |user, result|
    if result.is_a?(ResultTemplate)
      can_read_protocol_in_repository?(user, result.protocol)
    else
      can_read_my_module?(user, result.my_module)
    end
  end

  can :manage_result do |user, result|
    if result.is_a?(ResultTemplate)
      can_manage_protocol_draft_in_repository?(user, result.protocol)
    else
      !result.archived? &&
        !result.my_module.archived_branch? &&
        result.my_module.permission_granted?(user, MyModulePermissions::RESULTS_MANAGE)
    end
  end

  can :archive_result do |user, result|
    result.is_a?(Result) && can_manage_result?(user, result)
  end

  can :restore_result do |user, result|
    result.archived? &&
      !result.my_module.archived_branch? &&
      result.my_module.permission_granted?(user, MyModulePermissions::RESULTS_MANAGE)
  end

  can :delete_result do |user, result|
    if result.is_a?(ResultTemplate)
      can_manage_protocol_draft_in_repository?(user, result.protocol)
    else
      result.archived? &&
        result.team.settings['result_deletion_enabled'] &&
        !result.my_module.archived_branch? &&
        result.unlocked?(result) &&
        result.my_module.permission_granted?(user, MyModulePermissions::RESULTS_DELETE_ARCHIVED)
    end
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

Canaid::Permissions.register_for(ResultOrderableElement) do
  %i(manage_result_orderable_element
     archive_result_orderable_element
     restore_result_orderable_element
     delete_result_orderable_element)
    .each do |perm|
    can perm do |user, result_orderable_element|
      can_manage_result?(user, result_orderable_element.result)
    end
  end

  can :manage_result_orderable_element do |_, result_orderable_element|
    result_orderable_element.active?
  end

  can :archive_result_orderable_element do |_, result_orderable_element|
    result_orderable_element.result.is_a?(Result) && result_orderable_element.active?
  end

  can :restore_result_orderable_element do |_, result_orderable_element|
    result_orderable_element.archived?
  end

  can :delete_result_orderable_element do |_, result_orderable_element|
    (result_orderable_element.result.is_a?(ResultTemplate) || result_orderable_element.archived?) &&
      result_orderable_element.result.team.settings['result_deletion_enabled'] &&
      result_orderable_element.result.unlocked?(result_orderable_element.result)
  end
end
