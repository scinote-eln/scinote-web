# frozen_string_literal: true

class AddRepositoryFilterPermissions < ActiveRecord::Migration[6.1]
  REPOSITORY_FILTER_PERMISSION = [
    RepositoryPermissions::FILTERS_MANAGE
  ].freeze

  def change
    reversible do |dir|
      dir.up do
        @owner_role = UserRole.find_predefined_owner_role
        @normal_user_role = UserRole.find_predefined_normal_user_role
        @owner_role.permissions = @owner_role.permissions | REPOSITORY_FILTER_PERMISSION
        @normal_user_role.permissions = @normal_user_role.permissions | REPOSITORY_FILTER_PERMISSION
        @owner_role.save(validate: false)
        @normal_user_role.save(validate: false)
      end

      dir.down do
        @owner_role = UserRole.find_predefined_owner_role
        @normal_user_role = UserRole.find_predefined_normal_user_role
        @owner_role.permissions = @owner_role.permissions - REPOSITORY_FILTER_PERMISSION
        @normal_user_role.permissions = @normal_user_role.permissions - REPOSITORY_FILTER_PERMISSION
        @owner_role.save(validate: false)
        @normal_user_role.save(validate: false)
      end
    end
  end
end
