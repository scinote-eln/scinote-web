# frozen_string_literal: true

module PermissionExtends
  module ProjectPermissions
    %w(
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
    ).each { |permission| const_set(permission, "project_#{permission.underscore}") }
  end

  module ExperimentPermissions
    %w(
      READ
      READ_ARCHIVED
      MANAGE
      TASKS_MANAGE
      USERS_READ
      USERS_MANAGE
      READ_CANVAS
      ACTIVITIES_READ
    ).each { |permission| const_set(permission, "experiment_#{permission.underscore}") }
  end

  module MyModulePermissions
    %w(
      READ
      MANAGE
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
      STEPS_COMMENT_UPDATE_OWN
      REPOSITORY_ROWS_ASSIGN
      REPOSITORY_ROWS_MANAGE
      USERS_MANAGE
    ).each { |permission| const_set(permission, "task_#{permission.underscore}") }
  end

  module RepositoryPermissions
    %w(
      READ
      MANAGE
      ARCHIVE
      RESTORE
      SHARE
      CREATE_SNAPSHOT
      DELETE_SNAPSHOT
      CREATE_ROW
      UPDATE_ROW
      DELETE_ROW
      CREATE_COLUMN
      UPDATE_COLUMN
      DELETE_COLUMN
    ).each { |permission| const_set(permission, "inventory_#{permission.underscore}") }
  end

  module PredefinedRoles
    OWNER_PERMISSIONS = (
      ProjectPermissions.constants.map { |const| ProjectPermissions.const_get(const) } +
      ExperimentPermissions.constants.map { |const| ExperimentPermissions.const_get(const) } +
      MyModulePermissions.constants.map { |const| MyModulePermissions.const_get(const) }
    )

    NORMAL_USER_PERMISSIONS = [
      ProjectPermissions::READ,
      ProjectPermissions::READ_ARCHIVED,
      ProjectPermissions::ACTIVITIES_READ,
      ProjectPermissions::USERS_READ,
      ProjectPermissions::COMMENTS_READ,
      ProjectPermissions::COMMENTS_CREATE,
      ProjectPermissions::COMMENTS_MANAGE_OWN,
      ProjectPermissions::EXPERIMENTS_CREATE,
      ExperimentPermissions::READ,
      ExperimentPermissions::READ_CANVAS,
      ExperimentPermissions::MANAGE,
      ExperimentPermissions::TASKS_MANAGE,
      ExperimentPermissions::USERS_MANAGE,
      MyModulePermissions::READ,
      MyModulePermissions::MANAGE,
      MyModulePermissions::RESULTS_MANAGE,
      MyModulePermissions::PROTOCOL_MANAGE,
      MyModulePermissions::STEPS_MANAGE,
      MyModulePermissions::TAGS_MANAGE,
      MyModulePermissions::COMMENTS_CREATE,
      MyModulePermissions::COMMENTS_MANAGE,
      MyModulePermissions::COMMENTS_MANAGE_OWN,
      MyModulePermissions::COMPLETE,
      MyModulePermissions::UPDATE_STATUS,
      MyModulePermissions::STEPS_COMPLETE,
      MyModulePermissions::STEPS_UNCOMPLETE,
      MyModulePermissions::STEPS_CHECKLIST_CHECK,
      MyModulePermissions::STEPS_CHECKLIST_UNCHECK,
      MyModulePermissions::STEPS_COMMENTS_CREATE,
      MyModulePermissions::STEPS_COMMENTS_DELETE_OWN,
      MyModulePermissions::STEPS_COMMENT_UPDATE_OWN,
      MyModulePermissions::REPOSITORY_ROWS_ASSIGN,
      MyModulePermissions::REPOSITORY_ROWS_MANAGE
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
      MyModulePermissions::STEPS_COMMENT_UPDATE_OWN,
      MyModulePermissions::REPOSITORY_ROWS_ASSIGN,
      MyModulePermissions::REPOSITORY_ROWS_MANAGE
    ]

    VIEWER_PERMISSIONS = [
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
      MyModulePermissions::READ
    ]
  end
end
