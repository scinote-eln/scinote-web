# frozen_string_literal: true

Canaid::Permissions.register_for(Step) do
  can :manage_step do |user, step|
    if step.my_module
      step.active? && can_manage_my_module_steps?(user, step.my_module)
    else
      can_manage_protocol_draft_in_repository?(user, step.protocol)
    end
  end

  can :archive_step do |user, step|
    step.my_module && step.active? && can_manage_step?(user, step)
  end

  can :restore_step do |user, step|
    step.my_module && step.archived? && can_manage_my_module_steps?(user, step.my_module)
  end

  can :delete_step do |user, step|
    if step.my_module
      step.team.settings['protocol_steps_deletion_enabled'] && step.archived? && can_manage_my_module_steps?(user, step.my_module)
    else
      can_manage_protocol_draft_in_repository?(user, step.protocol)
    end
  end
end

Canaid::Permissions.register_for(StepOrderableElement) do
  %i(manage_step_orderable_element
     archive_step_orderable_element
     restore_step_orderable_element
     delete_step_orderable_element)
    .each do |perm|
    can perm do |user, step_orderable_element|
      can_manage_step?(user, step_orderable_element.step)
    end
  end

  can :manage_step_orderable_element do |_, step_orderable_element|
    step_orderable_element.active?
  end

  can :archive_step_orderable_element do |_, step_orderable_element|
    step_orderable_element.step.my_module && step_orderable_element.active?
  end

  can :restore_step_orderable_element do |_, step_orderable_element|
    step_orderable_element.archived?
  end

  can :delete_step_orderable_element do |_, step_orderable_element|
    if step_orderable_element.step.my_module
      step_orderable_element.step.team.settings['protocol_steps_deletion_enabled'] && step_orderable_element.archived?
    else
      true
    end
  end
end
