# frozen_string_literal: true

class AddStockConsumptionPermissionToUserRoles < ActiveRecord::Migration[6.1]
  USER_ROLE_NAMES = [
    I18n.t('user_roles.predefined.owner'),
    I18n.t('user_roles.predefined.normal_user'),
    I18n.t('user_roles.predefined.technician')
  ].freeze

  def up
    user_roles = UserRole.predefined.where(name: USER_ROLE_NAMES)

    user_roles.each do |user_role|
      next if user_role.permissions.include?(MyModulePermissions::STOCK_CONSUMPTION_UPDATE)

      user_role.permissions << MyModulePermissions::STOCK_CONSUMPTION_UPDATE
      user_role.save(validate: false)
    end
  end

  def down
    user_roles = UserRole.predefined.where(name: USER_ROLE_NAMES)

    user_roles.each do |user_role|
      next unless user_role.permissions.include?(MyModulePermissions::STOCK_CONSUMPTION_UPDATE)

      user_role.permissions.delete(MyModulePermissions::STOCK_CONSUMPTION_UPDATE)
      user_role.save(validate: false)
    end
  end
end
