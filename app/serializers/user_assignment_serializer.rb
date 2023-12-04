# frozen_string_literal: true

class UserAssignmentSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers

  attributes :id, :assigned, :assignable_type, :user, :user_role, :last_owner

  def user
    {
      id: object.user.id,
      name: object.user.name,
      avatar_url: avatar_path(object, :icon_small)
    }
  end

  def user_role
    {
      id: object.user_role.id,
      name: object.user_role.name
    }
  end

  def last_owner
    object.last_with_permission?("#{object.assignable.class.name}Permissions".constantize::USERS_MANAGE, assigned: :manually)
  end
end
