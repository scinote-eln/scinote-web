# frozen_string_literal: true

module PermissionExtends
  module ProjectPermissions
    %w(
      READ
      EXPORT
      MANAGE
      ARCHIVE
      RESTORE
      CREATE_EXPERIMENTS
      CREATE_COMMENTS
      EDIT_COMMENTS
      DELETE_COMMENTS
      MANAGE_TAGS
    ).each { |permission| const_set(permission, permission.underscore) }
  end

  module ExperimentPermissions
    %w(
      READ
      MANAGE
      ARCHIVE
      RESTORE
      CLONE
      MOVE
    ).each { |permission| const_set(permission, permission.underscore) }
  end

  module MyModulePermissions
    %w(
      MANAGE
      ARCHIVE
      RESTORE
      MOVE
      MANAGE_USERS
      ASSIGN_REPOSITORY_ROWS
      CHANGE_FLOW_STATUS
      CREATE_COMMENTS
      CREATE_REPOSITORY_SNAPSHOT
      MANAGE_REPOSITORY_SNAPSHOT
    ).each { |permission| const_set(permission, permission.underscore) }
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
    ).each { |permission| const_set(permission, permission.underscore) }
  end
end
