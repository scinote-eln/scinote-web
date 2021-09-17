# frozen_string_literal: true

module PermissionExtends
  module ProjectPermissions
    %w(
      READ
      READ_ARCHIVED
      MANAGE
      FOLDERS_READ
      ACTIVITIES_READ
      USERS_READ
      USERS_MANAGE
      COMMENTS_READ
      COMMENTS_CREATE
      COMMENTS_MANAGE
      EXPERIMENTS_READ
      EXPERIMENTS_READ_ARCHIVED
      EXPERIMENTS_CREATE
      EXPERIMENTS_READ_CANVAS
      EXPERIMENTS_ACTIVITIES_READ
      EXPERIMENTS_USERS_READ
      TASKS_MANAGE
    ).each { |permission| const_set(permission, "project_#{permission.underscore}") }
  end

  module ExperimentPermissions
    %w(
      READ
      MANAGE
      ARCHIVE
      RESTORE
      CLONE
      MOVE
      TASKS_CREATE
      MANAGE_ACCESS
    ).each { |permission| const_set(permission, "experiment_#{permission.underscore}") }
  end

  module MyModulePermissions
    %w(
      READ
      MANAGE
      UPDATE_START_DATE
      UPDATE_DUE_DATE
      UPDATE_NOTES
      TAGS_MANAGE
      STEPS_MANAGE
      COMMENTS_MANAGE
      COMMENTS_CREATE
      REPOSITORY_ROWS_ASSIGN
      REPOSITORY_ROWS_MANAGE
      RESULTS_MANAGE
      RESULTS_DELETE_ARCHIVED
      PROTOCOL_MANAGE
      COMPLETE
      UPDATE_STATUS
      STEPS_COMPLETE
      STEPS_UNCOMPLETE
      STEPS_CHECK
      STEPS_UNCHECK
      STEPS_COMMENTS_CREATE
      STEPS_COMMENTS_DELETE
      STEPS_COMMENTS_DELETE_OWN
      STEPS_COMMENTS_UPDATE
      STEPS_COMMENT_UPDATE_OWN
      REPOSITORY_ROWS_MANAGE
      REPOSITORY_ROWS_ASSIGN
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
end
