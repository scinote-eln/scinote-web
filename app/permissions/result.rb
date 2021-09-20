# frozen_string_literal: true

Canaid::Permissions.register_for(Result) do
  can :read_result do |user, result|
    can_read_my_module?(user, result.my_module.experiment)
  end

  can :manage_result do |user, result|
    !result.archived? &&
    result.unlocked?(result) &&
    result.my_module.permission_granted?(user, MyModulePermissions::RESULTS_MANAGE)
  end

  can :delete_result do |user, result|
    result.archived? &&
    result.unlocked?(result) &&
    result.my_module.permission_granted?(user, MyModulePermissions::RESULTS_DELETE_ARCHIVED)
  end
end
