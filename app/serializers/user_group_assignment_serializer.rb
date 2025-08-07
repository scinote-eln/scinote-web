# frozen_string_literal: true

class UserGroupAssignmentSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers

  attributes :id, :user_role, :user_group, :inherit_message
  attribute :current_user

  def user_group
    {
      id: object.user_group.id,
      name: object.user_group.name
    }
  end

  def current_user
    return false if object.assignable.user_assignments.exists?(user_id: instance_options[:user].id)

    object.user_group.users.exists?(id: instance_options[:user].id)
  end

  def user_role
    {
      id: object.user_role.id,
      name: object.user_role.name
    }
  end

  def inherit_message
    user_group_assignment_resource_role_name(object.user_group, object.assignable, inherit = '')
  end

  private

  def user_group_assignment_resource_role_name(user_group, resource, inherit = '')
    user_group_assignment = resource.user_group_assignments.find_by(user_group: user_group)

    return '' if ([Project, Protocol].include?(resource.class) && inherit.blank?) || user_group_assignment.blank?

    if user_group_assignment.automatically_assigned? && resource.permission_parent.present?
      parent = resource.permission_parent
      return user_group_assignment_resource_role_name(user_group, parent, '_inherit')
    end

    I18n.t("access_permissions.partials.#{resource.class.to_s.downcase}_tooltip#{inherit}")
  end
end
