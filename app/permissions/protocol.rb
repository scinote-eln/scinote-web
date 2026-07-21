Canaid::Permissions.register_for(Protocol) do
  %i(manage_protocol_in_repository
     manage_protocol_draft_in_repository
     clone_protocol_in_repository
     publish_protocol_in_repository
     delete_protocol_draft_in_repository
     save_protocol_version_as_draft)
    .each do |perm|
    can perm do |_, protocol|
      protocol.active?
    end
  end

  # protocol in repository: read, export, read step, read/download step asset
  can :read_protocol_in_repository do |user, protocol|
    protocol.permission_granted?(user, ProtocolPermissions::READ)
  end

  # protocol in repository: update, create/update/delete/reorder step,
  #                         toggle private/public visibility, archive
  can :manage_protocol_in_repository do |user, protocol|
    protocol.in_repository_draft? &&
      protocol.permission_granted?(user, ProtocolPermissions::MANAGE)
  end

  can :manage_protocol_draft_in_repository do |user, protocol|
    protocol.in_repository_draft? &&
      protocol.permission_granted?(user, ProtocolPermissions::MANAGE_DRAFT)
  end

  can :manage_protocol_users do |user, protocol|
    protocol.permission_granted?(user, ProtocolPermissions::USERS_MANAGE) ||
      protocol.team.permission_granted?(user, TeamPermissions::MANAGE)
  end

  # protocol in repository: restore
  can :restore_protocol_in_repository do |user, protocol|
    protocol.archived? && protocol.permission_granted?(user, ProtocolPermissions::MANAGE)
  end

  can :archive_protocol_in_repository do |user, protocol|
    protocol.active? && protocol.permission_granted?(user, ProtocolPermissions::MANAGE)
  end

  # protocol in repository: copy
  can :clone_protocol_in_repository do |user, protocol|
    can_read_protocol_in_repository?(user, protocol) && can_create_protocols_in_repository?(user, protocol.team)
  end

  can :publish_protocol_in_repository do |user, protocol|
    protocol.in_repository_draft? &&
      protocol.permission_granted?(user, ProtocolPermissions::MANAGE)
  end

  can :delete_protocol_draft_in_repository do |user, protocol|
    protocol.parent_id.present? &&
      can_manage_protocol_draft_in_repository?(user, protocol)
  end

  can :save_protocol_version_as_draft do |user, protocol|
    next false unless protocol.in_repository_published?

    protocol.permission_granted?(user, ProtocolPermissions::MANAGE_DRAFT)
  end

  can :create_result_templates do |user, protocol|
    can_manage_protocol_draft_in_repository?(user, protocol)
  end

  can :update_protocol_name do |user, protocol|
    if protocol.in_module?
      !protocol.description_locked? && can_manage_my_module_protocol?(user, protocol.my_module)
    else
      can_manage_protocol_draft_in_repository?(user, protocol)
    end
  end

  can :update_protocol_description do |user, protocol|
    if protocol.in_module?
      !protocol.description_locked? && can_manage_my_module_protocol?(user, protocol.my_module)
    else
      can_manage_protocol_draft_in_repository?(user, protocol)
    end
  end

  can :reorder_protocol_steps do |user, protocol|
    (can_manage_protocol_in_module?(user, protocol) && protocol.steps.locked.none?) ||
      can_manage_protocol_draft_in_repository?(user, protocol)
  end

  can :create_protocol_steps do |user, protocol|
    can_manage_protocol_draft_in_repository?(user, protocol) ||
      (can_manage_protocol_in_module?(user, protocol) && protocol.adding_steps_allowed?)
  end

  can :revert_protocol do |user, protocol|
    protocol.linked? &&
      protocol.parent.active? &&
      protocol.newer_than_parent? &&
      protocol.steps.locked.none? &&
      can_manage_protocol_in_module?(user, protocol) &&
      can_read_protocol_in_repository?(user, protocol.parent)
  end

  can :unlink_protocol do |user, protocol|
    protocol.linked? && protocol.steps.locked.none? && can_manage_protocol_in_module?(user, protocol)
  end

  can :archive_all_protocol_steps do |user, protocol|
    protocol.steps.locked.none? && can_manage_protocol_in_module?(user, protocol)
  end
end
