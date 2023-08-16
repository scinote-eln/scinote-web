# frozen_string_literal: true

Canaid::Permissions.register_for(Step) do
  can :manage_step do |user, step|
    if step.my_module
      can_manage_my_module_steps?(user, step.my_module)
    else
      can_manage_protocol_in_repository?(user, step.protocol)
    end
  end

  can :create_step_comments do |user, step|
    if step.my_module
      can_create_comments_in_my_module_steps(user, step.my_module)
    else
      can_manage_protocol_in_repository?(user, step.protocol)
    end
  end
end
