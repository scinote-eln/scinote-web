# frozen_string_literal: true

module PermissionExtends
  module TeamPermissions
    %w(
      NONE
      READ
      MANAGE
      USERS_MANAGE
      PROJECTS_CREATE
      INVENTORIES_CREATE
      PROTOCOLS_CREATE
      FORMS_CREATE
      REPORTS_CREATE
      LABEL_TEMPLATES_READ
      LABEL_TEMPLATES_MANAGE
      STORAGE_LOCATIONS_CREATE
      STORAGE_LOCATIONS_MANAGE
      STORAGE_LOCATIONS_READ
      STORAGE_LOCATION_CONTAINERS_CREATE
      STORAGE_LOCATION_CONTAINERS_MANAGE
      STORAGE_LOCATION_CONTAINERS_READ
    ).each { |permission| const_set(permission, "team_#{permission.parameterize}") }
  end

  module ProtocolPermissions
    %w(
      NONE
      READ
      READ_ARCHIVED
      MANAGE
      USERS_MANAGE
      MANAGE_DRAFT
    ).each { |permission| const_set(permission, "protocol_#{permission.parameterize}") }
  end

  module FormPermissions
    %w(
      NONE
      READ
      READ_ARCHIVED
      MANAGE
      MANAGE_DRAFT
      USERS_MANAGE
    ).each { |permission| const_set(permission, "form_#{permission.parameterize}") }
  end

  module FormResponsePermissions
    %w(
      NONE
      CREATE
      SUBMIT
      RESET
    ).each { |permission| const_set(permission, "form_response_#{permission.parameterize}") }
  end

  module ReportPermissions
    %w(
      NONE
      READ
      MANAGE
      USERS_MANAGE
    ).each { |permission| const_set(permission, "report_#{permission.parameterize}") }
  end

  module ProjectPermissions
    %w(
      NONE
      READ
      READ_ARCHIVED
      MANAGE
      ACTIVITIES_READ
      USERS_READ
      USERS_MANAGE
      COMMENTS_READ
      COMMENTS_CREATE
      COMMENTS_MANAGE
      COMMENTS_MANAGE_OWN
      TAGS_MANAGE
      EXPERIMENTS_CREATE
    ).each { |permission| const_set(permission, "project_#{permission.parameterize}") }
  end

  module ExperimentPermissions
    %w(
      NONE
      READ
      READ_ARCHIVED
      MANAGE
      TASKS_CREATE
      USERS_READ
      USERS_MANAGE
      READ_CANVAS
      ACTIVITIES_READ
    ).each { |permission| const_set(permission, "experiment_#{permission.parameterize}") }
  end

  module MyModulePermissions
    %w(
      NONE
      READ
      READ_ARCHIVED
      ACTIVITIES_READ
      MANAGE
      SHARE
      UPDATE_START_DATE
      UPDATE_DUE_DATE
      UPDATE_DESCRIPTION
      STEPS_MANAGE
      UPDATE_STATUS
      COMMENTS_CREATE
      COMMENTS_MANAGE
      COMMENTS_MANAGE_OWN
      RESULTS_MANAGE
      RESULTS_DELETE_ARCHIVED
      RESULTS_COMMENTS_MANAGE
      RESULTS_COMMENTS_MANAGE_OWN
      RESULTS_COMMENTS_CREATE
      TAGS_MANAGE
      PROTOCOL_MANAGE
      COMPLETE
      STEPS_COMPLETE
      STEPS_UNCOMPLETE
      STEPS_CHECKLIST_CHECK
      STEPS_CHECKLIST_UNCHECK
      STEPS_COMMENTS_CREATE
      STEPS_COMMENTS_DELETE
      STEPS_COMMENTS_DELETE_OWN
      STEPS_COMMENTS_UPDATE
      STEPS_COMMENTS_UPDATE_OWN
      REPOSITORY_ROWS_ASSIGN
      REPOSITORY_ROWS_MANAGE
      USERS_READ
      USERS_MANAGE
      DESIGNATED_USERS_MANAGE
      STOCK_CONSUMPTION_UPDATE
    ).each { |permission| const_set(permission, "task_#{permission.parameterize}") }
  end

  module RepositoryPermissions
    %w(
      NONE
      READ
      READ_ARCHIVED
      MANAGE
      RESTORE
      DELETE
      SHARE
      ROWS_CREATE
      ROWS_UPDATE
      ROWS_DELETE
      COLUMNS_CREATE
      COLUMNS_UPDATE
      COLUMNS_DELETE
      USERS_MANAGE
      FILTERS_MANAGE
    ).each { |permission| const_set(permission, "inventory_#{permission.parameterize}") }
  end

  module PredefinedRoles
    OWNER_PERMISSIONS = (
      TeamPermissions.constants.map { |const| TeamPermissions.const_get(const) } +
      ProtocolPermissions.constants.map { |const| ProtocolPermissions.const_get(const) } +
      FormPermissions.constants.map { |const| FormPermissions.const_get(const) } +
      ReportPermissions.constants.map { |const| ReportPermissions.const_get(const) } +
      ProjectPermissions.constants.map { |const| ProjectPermissions.const_get(const) } +
      ExperimentPermissions.constants.map { |const| ExperimentPermissions.const_get(const) } +
      MyModulePermissions.constants.map { |const| MyModulePermissions.const_get(const) } +
      RepositoryPermissions.constants.map { |const| RepositoryPermissions.const_get(const) } +
      FormResponsePermissions.constants.map { |const| FormResponsePermissions.const_get(const) }
    ).reject { |p| p.end_with?('_none') }

    NORMAL_USER_PERMISSIONS = [
      TeamPermissions::PROJECTS_CREATE,
      TeamPermissions::PROTOCOLS_CREATE,
      TeamPermissions::REPORTS_CREATE,
      TeamPermissions::FORMS_CREATE,
      TeamPermissions::LABEL_TEMPLATES_READ,
      TeamPermissions::LABEL_TEMPLATES_MANAGE,
      TeamPermissions::STORAGE_LOCATIONS_READ,
      TeamPermissions::STORAGE_LOCATIONS_CREATE,
      TeamPermissions::STORAGE_LOCATIONS_MANAGE,
      TeamPermissions::STORAGE_LOCATION_CONTAINERS_READ,
      TeamPermissions::STORAGE_LOCATION_CONTAINERS_CREATE,
      TeamPermissions::STORAGE_LOCATION_CONTAINERS_MANAGE,
      ProtocolPermissions::READ,
      ProtocolPermissions::READ_ARCHIVED,
      ProtocolPermissions::MANAGE_DRAFT,
      FormPermissions::READ,
      FormPermissions::MANAGE_DRAFT,
      FormPermissions::READ_ARCHIVED,
      FormResponsePermissions::CREATE,
      FormResponsePermissions::SUBMIT,
      FormResponsePermissions::RESET,
      ReportPermissions::READ,
      ReportPermissions::MANAGE,
      ProjectPermissions::READ,
      ProjectPermissions::READ_ARCHIVED,
      ProjectPermissions::ACTIVITIES_READ,
      ProjectPermissions::USERS_READ,
      ProjectPermissions::COMMENTS_READ,
      ProjectPermissions::COMMENTS_CREATE,
      ProjectPermissions::COMMENTS_MANAGE_OWN,
      ProjectPermissions::EXPERIMENTS_CREATE,
      ProjectPermissions::TAGS_MANAGE,
      ExperimentPermissions::READ,
      ExperimentPermissions::READ_CANVAS,
      ExperimentPermissions::MANAGE,
      ExperimentPermissions::TASKS_CREATE,
      ExperimentPermissions::USERS_READ,
      MyModulePermissions::READ,
      MyModulePermissions::READ_ARCHIVED,
      MyModulePermissions::ACTIVITIES_READ,
      MyModulePermissions::MANAGE,
      MyModulePermissions::SHARE,
      MyModulePermissions::UPDATE_START_DATE,
      MyModulePermissions::UPDATE_DUE_DATE,
      MyModulePermissions::UPDATE_DESCRIPTION,
      MyModulePermissions::RESULTS_MANAGE,
      MyModulePermissions::RESULTS_COMMENTS_MANAGE_OWN,
      MyModulePermissions::RESULTS_COMMENTS_CREATE,
      MyModulePermissions::PROTOCOL_MANAGE,
      MyModulePermissions::STEPS_MANAGE,
      MyModulePermissions::TAGS_MANAGE,
      MyModulePermissions::COMMENTS_CREATE,
      MyModulePermissions::COMMENTS_MANAGE_OWN,
      MyModulePermissions::COMPLETE,
      MyModulePermissions::UPDATE_STATUS,
      MyModulePermissions::STEPS_COMPLETE,
      MyModulePermissions::STEPS_UNCOMPLETE,
      MyModulePermissions::STEPS_CHECKLIST_CHECK,
      MyModulePermissions::STEPS_CHECKLIST_UNCHECK,
      MyModulePermissions::STEPS_COMMENTS_CREATE,
      MyModulePermissions::STEPS_COMMENTS_DELETE_OWN,
      MyModulePermissions::STEPS_COMMENTS_UPDATE_OWN,
      MyModulePermissions::REPOSITORY_ROWS_ASSIGN,
      MyModulePermissions::REPOSITORY_ROWS_MANAGE,
      MyModulePermissions::USERS_READ,
      MyModulePermissions::STOCK_CONSUMPTION_UPDATE,
      RepositoryPermissions::READ,
      RepositoryPermissions::READ_ARCHIVED,
      RepositoryPermissions::COLUMNS_CREATE,
      RepositoryPermissions::COLUMNS_UPDATE,
      RepositoryPermissions::COLUMNS_DELETE,
      RepositoryPermissions::ROWS_CREATE,
      RepositoryPermissions::ROWS_UPDATE,
      RepositoryPermissions::ROWS_DELETE,
      RepositoryPermissions::FILTERS_MANAGE
    ]

    TECHNICIAN_PERMISSIONS = [
      ProjectPermissions::READ,
      ProjectPermissions::READ_ARCHIVED,
      ProjectPermissions::ACTIVITIES_READ,
      ProjectPermissions::USERS_READ,
      ProjectPermissions::COMMENTS_READ,
      ProjectPermissions::COMMENTS_CREATE,
      ProjectPermissions::COMMENTS_MANAGE_OWN,
      ExperimentPermissions::READ,
      ExperimentPermissions::READ_CANVAS,
      ExperimentPermissions::READ_ARCHIVED,
      ExperimentPermissions::ACTIVITIES_READ,
      ExperimentPermissions::USERS_READ,
      MyModulePermissions::READ,
      MyModulePermissions::READ_ARCHIVED,
      MyModulePermissions::ACTIVITIES_READ,
      MyModulePermissions::COMMENTS_CREATE,
      MyModulePermissions::COMMENTS_MANAGE_OWN,
      MyModulePermissions::COMPLETE,
      MyModulePermissions::RESULTS_COMMENTS_MANAGE_OWN,
      MyModulePermissions::RESULTS_COMMENTS_CREATE,
      MyModulePermissions::UPDATE_STATUS,
      MyModulePermissions::STEPS_COMPLETE,
      MyModulePermissions::STEPS_UNCOMPLETE,
      MyModulePermissions::STEPS_CHECKLIST_CHECK,
      MyModulePermissions::STEPS_CHECKLIST_UNCHECK,
      MyModulePermissions::STEPS_COMMENTS_CREATE,
      MyModulePermissions::STEPS_COMMENTS_DELETE_OWN,
      MyModulePermissions::STEPS_COMMENTS_UPDATE_OWN,
      MyModulePermissions::REPOSITORY_ROWS_ASSIGN,
      MyModulePermissions::REPOSITORY_ROWS_MANAGE,
      MyModulePermissions::USERS_READ,
      MyModulePermissions::STOCK_CONSUMPTION_UPDATE,
      FormResponsePermissions::SUBMIT
    ]

    VIEWER_PERMISSIONS = [
      TeamPermissions::LABEL_TEMPLATES_READ,
      TeamPermissions::STORAGE_LOCATIONS_READ,
      TeamPermissions::STORAGE_LOCATION_CONTAINERS_READ,
      ProtocolPermissions::READ,
      ProtocolPermissions::READ_ARCHIVED,
      FormPermissions::READ,
      FormPermissions::READ_ARCHIVED,
      ReportPermissions::READ,
      ProjectPermissions::READ,
      ProjectPermissions::READ_ARCHIVED,
      ProjectPermissions::ACTIVITIES_READ,
      ProjectPermissions::USERS_READ,
      ProjectPermissions::COMMENTS_READ,
      ExperimentPermissions::READ,
      ExperimentPermissions::READ_CANVAS,
      ExperimentPermissions::READ_ARCHIVED,
      ExperimentPermissions::ACTIVITIES_READ,
      ExperimentPermissions::USERS_READ,
      MyModulePermissions::READ,
      MyModulePermissions::USERS_READ,
      MyModulePermissions::READ_ARCHIVED,
      MyModulePermissions::ACTIVITIES_READ,
      RepositoryPermissions::READ,
      RepositoryPermissions::READ_ARCHIVED
    ]
  end
end
