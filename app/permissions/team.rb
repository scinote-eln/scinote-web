Canaid::Permissions.register_for(Team) do
  # team: leave, read users, read projects
  #       read protocols
  #
  can :read_team do |user, team|
    user.member_of_team?(team)
  end

  # team: update
  can :manage_team do |user, team|
    team.permission_granted?(user, TeamPermissions::MANAGE, team)
  end

  # team: assign/unassing user, change user role
  can :manage_team_users do |user, team|
    team.permission_granted?(user, TeamPermissions::USERS_MANAGE, team)
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

  can :create_storage_locations do |user, team|
    team.permission_granted?(user, TeamPermissions::STORAGE_LOCATIONS_CREATE)
  end

  can :create_storage_location_containers do |user, team|
    team.permission_granted?(user, TeamPermissions::STORAGE_LOCATION_CONTAINERS_CREATE)
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

  can :create_forms do |user, team|
    team.permission_granted?(user, TeamPermissions::FORMS_CREATE)
  end

  can :create_tags do |user, team|
    team.permission_granted?(user, TeamPermissions::TAGS_CREATE)
  end

  can :update_tags do |user, team|
    team.permission_granted?(user, TeamPermissions::TAGS_UPDATE)
  end

  can :delete_tags do |user, team|
    team.permission_granted?(user, TeamPermissions::TAGS_DELETE)
  end

  can :modify_team_deletion_prevention do |user, team|
    Team.deletion_prevention_enabled? && can_manage_team?(user, team)
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
