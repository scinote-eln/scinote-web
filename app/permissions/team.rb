Canaid::Permissions.register_for(Team) do
  # team: leave, read users, read projects
  #       read protocols
  #
  can :read_team do |user, team|
    user.member_of_team?(team)
  end

  # team: update
  can :manage_team do |user, team|
    team.permission_granted?(user, TeamPermissions::MANAGE)
  end

  # team: assign/unassing user, change user role
  can :manage_team_users do |user, team|
    team.permission_granted?(user, TeamPermissions::USERS_MANAGE)
  end

  # team: invite new users to the team
  can :invite_team_users do |user, team|
    can_manage_team_users?(user, team)
  end

  # project_folder: create
  can :create_project_folders do |user, team|
    can_manage_team?(user, team)
  end

  # project: create
  can :create_projects do |user, team|
    team.permission_granted?(user, TeamPermissions::PROJECTS_CREATE)
  end

  # protocol in repository: create, import
  can :create_protocols_in_repository do |user, team|
    team.permission_granted?(user, TeamPermissions::PROTOCOLS_CREATE)
  end

  # repository: create, copy
  can :create_repositories do |user, team|
    within_limits = Repository.within_global_limits?
    within_limits = Repository.within_team_limits?(team) if within_limits
    within_limits && team.permission_granted?(user, TeamPermissions::INVENTORIES_CREATE)
  end

  can :create_reports do |user, team|
    team.permission_granted?(user, TeamPermissions::REPORTS_CREATE)
  end

  can :view_label_templates do |user, team|
    team.permission_granted?(user, TeamPermissions::LABEL_TEMPLATES_READ)
  end

  can :manage_label_templates do |user, team|
    team.permission_granted?(user, TeamPermissions::LABEL_TEMPLATES_MANAGE)
  end
end

Canaid::Permissions.register_for(ProjectFolder) do
  # ProjectFolder: delete
  can :delete_project_folder do |user, project_folder|
    can_manage_team?(user, project_folder.team) &&
      project_folder.projects.none? &&
      project_folder.project_folders.none?
  end
end

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
end

Canaid::Permissions.register_for(Report) do
  can :read_report do |user, report|
    can_read_project?(report.project) && report.permission_granted?(user, ReportPermissions::READ)
  end

  can :manage_report do |user, report|
    can_read_project?(report.project) && report.permission_granted?(user, ReportPermissions::MANAGE)
  end

  can :manage_report_users do |user, report|
    report.permission_granted?(user, ReportPermissions::USERS_MANAGE)
  end
end
