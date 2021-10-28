# frozen_string_literal: true

module UserRolesHelper
  def user_roles_collection
    Rails.cache.fetch([current_user, 'available_user_roles']) do
      @user_roles_collection ||= UserRole.order(id: :asc).pluck(:name, :id)
    end
  end
end
