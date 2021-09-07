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
      CREATE_TASKS
      MANAGE_ACCESS
    ).each { |permission| const_set(permission, "experiment_#{permission.underscore}") }
  end

  module MyModulePermissions
    %w(
      READ
      MANAGE
      ARCHIVE
      RESTORE
      MOVE
      MANAGE_USERS
      ASSIGN_REPOSITORY_ROWS
      CHANGE_FLOW_STATUS
      CREATE_COMMENTS
      MANAGE_COMMENTS
      CREATE_REPOSITORY_SNAPSHOT
      MANAGE_REPOSITORY_SNAPSHOT
      MANAGE_ACCESS
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
