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
      step.team.protocol_steps_deletion_enabled? && step.archived? && can_manage_my_module_steps?(user, step.my_module)
    else
      can_manage_protocol_draft_in_repository?(user, step.protocol)
    end
  end
end

Canaid::Permissions.register_for(StepText) do
  %i(manage_step_text
     archive_step_text
     restore_step_text
     delete_step_text)
    .each do |perm|
    can perm do |user, step_text|
      can_manage_step?(user, step_text.step)
    end
  end

  %i(manage_step_text archive_step_text).each do |perm|
    can perm do |user, step_text|
      !step_text.locked? || can_manage_protocol_draft_in_repository?(user, step_text.step.protocol)
    end
  end

  can :manage_step_text do |_, step_text|
    step_text.active?
  end

  can :archive_step_text do |_, step_text|
    step_text.active? && step_text.step.protocol.in_module?
  end

  can :restore_step_text do |_, step_text|
    step_text.archived?
  end

  can :delete_step_text do |user, step_text|
    if step_text.step.protocol.in_module?
      !step_text.locked? && step_text.archived? && step_text.step.team.protocol_steps_deletion_enabled?
    else
      !step_text.locked? || can_manage_protocol_draft_in_repository?(user, step_text.step.protocol)
    end
  end

  can :lock_step_text do |user, step_text|
    can_manage_protocol_draft_in_repository?(user, step_text.step.protocol)
  end

  can :unlock_step_text do |user, step_text|
    can_manage_protocol_draft_in_repository?(user, step_text.step.protocol)
  end
end

Canaid::Permissions.register_for(FormResponse) do
  %i(manage_step_form_response
     archive_step_form_response
     restore_step_form_response
     delete_step_form_response)
    .each do |perm|
    can perm do |user, form_response|
      can_manage_step?(user, form_response.step)
    end
  end

  %i(manage_step_form_response archive_step_form_response).each do |perm|
    can perm do |user, form_response|
      !form_response.locked? || can_manage_protocol_draft_in_repository?(user, form_response.step.protocol)
    end
  end

  can :manage_step_form_response do |_, form_response|
    form_response.active?
  end

  can :archive_step_form_response do |_, form_response|
    form_response.active? && form_response.step.protocol.in_module?
  end

  can :restore_step_form_response do |_, form_response|
    form_response.archived?
  end

  can :delete_step_form_response do |user, form_response|
    if form_response.step.protocol.in_module?
      !form_response.locked? && form_response.archived? && form_response.step.team.protocol_steps_deletion_enabled?
    else
      !form_response.locked? || can_manage_protocol_draft_in_repository?(user, form_response.step.protocol)
    end
  end

  can :lock_step_form_response do |user, form_response|
    can_manage_protocol_draft_in_repository?(user, form_response.step.protocol)
  end

  can :unlock_step_form_response do |user, form_response|
    can_manage_protocol_draft_in_repository?(user, form_response.step.protocol)
  end
end

Canaid::Permissions.register_for(Checklist) do
  %i(manage_step_checklist
     archive_step_checklist
     restore_step_checklist
     delete_step_checklist)
    .each do |perm|
    can perm do |user, checklist|
      can_manage_step?(user, checklist.step)
    end
  end

  %i(manage_step_checklist archive_step_checklist).each do |perm|
    can perm do |user, checklist|
      !checklist.locked? || can_manage_protocol_draft_in_repository?(user, checklist.step.protocol)
    end
  end

  can :manage_step_checklist do |_, checklist|
    checklist.active?
  end

  can :archive_step_checklist do |_, checklist|
    checklist.active? && checklist.step.protocol.in_module?
  end

  can :restore_step_checklist do |_, checklist|
    checklist.archived?
  end

  can :delete_step_checklist do |user, checklist|
    if checklist.step.protocol.in_module?
      !checklist.locked? && checklist.archived? && checklist.step.team.protocol_steps_deletion_enabled?
    else
      !checklist.locked? || can_manage_protocol_draft_in_repository?(user, checklist.step.protocol)
    end
  end

  can :lock_step_checklist do |user, checklist|
    can_manage_protocol_draft_in_repository?(user, checklist.step.protocol)
  end

  can :unlock_step_checklist do |user, checklist|
    can_manage_protocol_draft_in_repository?(user, checklist.step.protocol)
  end
end

Canaid::Permissions.register_for(Table) do
  %i(manage_step_table
     archive_step_table
     restore_step_table
     delete_step_table)
    .each do |perm|
    can perm do |user, table|
      can_manage_step?(user, table.step)
    end
  end

  %i(manage_step_table archive_step_table).each do |perm|
    can perm do |user, table|
      !table.locked? || can_manage_protocol_draft_in_repository?(user, table.step.protocol)
    end
  end

  can :manage_step_table do |_, table|
    table.active?
  end

  can :archive_step_table do |_, table|
    table.active? && table.step.protocol.in_module?
  end

  can :restore_step_table do |_, table|
    table.archived?
  end

  can :delete_step_table do |user, table|
    if table.step.protocol.in_module?
      !table.locked? && table.archived? && table.step.team.protocol_steps_deletion_enabled?
    else
      !table.locked? || can_manage_protocol_draft_in_repository?(user, table.step.protocol)
    end
  end

  can :lock_step_table do |user, table|
    can_manage_protocol_draft_in_repository?(user, table.step.protocol)
  end

  can :unlock_step_table do |user, table|
    can_manage_protocol_draft_in_repository?(user, table.step.protocol)
  end
end
