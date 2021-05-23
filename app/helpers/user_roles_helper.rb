# frozen_string_literal: true

module UserRolesHelper
  def user_roles_collection
    Rails.cache.fetch([current_user, 'available_user_roles']) do
      @user_roles_collection ||= UserRole.all.pluck(:name, :id)
    end
  end

  def legacy_user_role_parser(name)
    case name
    when I18n.t('user_roles.predefined.owner')
      'owner'
    when I18n.t('user_roles.predefined.normal_user')
      'normal_user'
    when I18n.t('user_roles.predefined.technician')
      'technician'
    when I18n.t('user_roles.predefined.viewer')
      'viewer'
    end
  end
end
