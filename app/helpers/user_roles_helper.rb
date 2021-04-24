# frozen_string_literal: true

module UserRolesHelper
  def user_roles_collection
    Rails.cache.fetch([current_user, 'available_user_roles']) do
      @user_roles_collection ||= [[t('user_assignment.select.default_option'), nil]] + UserRole.all.pluck(:name, :id)
    end
  end
end
