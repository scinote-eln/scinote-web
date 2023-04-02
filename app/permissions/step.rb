# frozen_string_literal: true

Canaid::Permissions.register_for(Step) do
  can :manage_step do |user, step|
    if step.my_module
      can_manage_my_module_steps?(user, step.my_module)
    else
      can_manage_protocol_draft_in_repository?(user, step.protocol)
    end
  end
end
