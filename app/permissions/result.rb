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

Canaid::Permissions.register_for(ResultText) do
  %i(manage_result_text
     archive_result_text
     restore_result_text
     delete_result_text)
    .each do |perm|
    can perm do |user, result_text|
      can_manage_result?(user, result_text.result)
    end
  end

  can :manage_result_text do |_, result_text|
    result_text.active?
  end

  can :archive_result_text do |_, result_text|
    result_text.active? && result_text.result.is_a?(Result)
  end

  can :restore_result_text do |_, result_text|
    result_text.archived?
  end

  can :delete_result_text do |_, result_text|
    if result_text.result.is_a?(ResultTemplate)
      result_text.result.unlocked?(result_text.result)
    else
      result_text.archived? && result_text.result.team.settings['result_deletion_enabled'] &&
        result_text.result.unlocked?(result_text.result)
    end
  end
end

Canaid::Permissions.register_for(Table) do
  %i(manage_result_table
     archive_result_table
     restore_result_table
     delete_result_table)
    .each do |perm|
    can perm do |user, table|
      can_manage_result?(user, table.result)
    end
  end

  can :manage_result_table do |_, table|
    table.active?
  end

  can :archive_result_table do |_, table|
    table.active? && table.result.is_a?(Result)
  end

  can :restore_result_table do |_, table|
    table.archived?
  end

  can :delete_result_table do |_, table|
    if table.result.is_a?(ResultTemplate)
      table.result.unlocked?(table.result)
    else
      table.archived? && table.result.team.settings['result_deletion_enabled'] &&
        table.result.unlocked?(table.result)
    end
  end
end
