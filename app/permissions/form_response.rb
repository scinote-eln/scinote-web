# frozen_string_literal: true

Canaid::Permissions.register_for(FormResponse) do
  %i(
    submit_form_response
    reset_form_response
  ).each do |perm|
    can perm do |_, form_response|
      !form_response.locked?
    end
  end

  can :submit_form_response do |user, form_response|
    parent = form_response.parent
    case parent
    when Step
      next false unless parent.protocol.my_module # protocol template forms can't be submitted
      next false if parent.protocol.my_module.archived
      next false unless form_response.pending?

      parent.protocol.my_module.permission_granted?(user, FormResponsePermissions::SUBMIT)
    end
  end

  can :reset_form_response do |user, form_response|
    parent = form_response.parent
    case parent
    when Step
      next false unless parent.protocol.my_module # protocol template forms can't be reset
      next false if parent.protocol.my_module.archived
      next false unless form_response.submitted?

      parent.protocol.my_module.permission_granted?(user, FormResponsePermissions::RESET)
    end
  end
end

Canaid::Permissions.register_for(Protocol) do
  can :create_protocol_form_responses do |user, protocol|
    (protocol.my_module || protocol).permission_granted?(user, FormResponsePermissions::CREATE)
  end
end
