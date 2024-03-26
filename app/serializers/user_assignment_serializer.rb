# frozen_string_literal: true

class UserAssignmentSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers

  attributes :id, :assigned, :assignable_type, :user, :user_role, :last_owner, :inherit_message
  attribute :current_user

  def assigned
    parent_assignment(parent)&.assigned
  end

  def parent
    object.assignable.permission_parent
  end

  def user
    {
      id: object.user.id,
      name: object.user.name,
      avatar_url: avatar_path(object.user, :icon_small)
    }
  end

  def current_user
    instance_options[:user].id == object.user.id
  end

  def user_role
    {
      id: object.user_role.id,
      name: object.user_role.name
    }
  end

  def last_owner
    parent_assignment(parent)&.last_with_permission?(ProjectPermissions::USERS_MANAGE, assigned: :manually)
  end

  def inherit_message
    user_assignment_resource_role_name(object.user, object.assignable, inherit = '')
  end

  private

  def parent_assignment(parent)
    return object if parent.blank?

    case parent
    when Project
      parent.user_assignments.find_by(user: object.user)
    when Experiment
      parent_assignment(parent.permission_parent)
    when Team
      object
    end
  end

  def user_assignment_resource_role_name(user, resource, inherit = '')
    user_assignment = resource.user_assignments.find_by(user: user)

    return '' if ([Project, Protocol].include?(resource.class) && inherit.blank?) || user_assignment.blank?

    if user_assignment.automatically_assigned? && resource.permission_parent.present?
      parent = resource.permission_parent
      return user_assignment_resource_role_name(user, parent, '_inherit')
    end

    I18n.t("access_permissions.partials.#{resource.class.to_s.downcase}_tooltip#{inherit}")
  end
end
