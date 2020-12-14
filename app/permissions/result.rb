# frozen_string_literal: true

Canaid::Permissions.register_for(Result) do
  can :read_result do |user, result|
    can_read_experiment?(user, result.my_module.experiment)
  end

  can :manage_result do |user, result|
    can_manage_module?(user, result.my_module) && result.active? && result.unlocked?(result)
  end
end
