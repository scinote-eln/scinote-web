# frozen_string_literal: true

Canaid::Permissions.register_for(ResultTemplate) do
  can :read_result_template do |user, result_template|
    can_read_protocol_in_repository?(user, result_template.protocol)
  end

  can :manage_result_template do |user, result_template|
    can_manage_protocol_draft_in_repository?(user, result_template.protocol)
  end

  can :delete_result_template do |user, result_template|
    can_manage_protocol_draft_in_repository?(user, result_template.protocol)
  end
end
