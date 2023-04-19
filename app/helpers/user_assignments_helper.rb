# frozen_string_literal: true

module UserAssignmentsHelper
  def current_assignee_name(assignee)
    display_name = if assignee == current_user
                     [assignee.name, t('user_assignment.current_assignee')].join(' ')
                   else
                     assignee.name
                   end
    escape_input(display_name)
  end

  def user_assignment_resource_role_name(user, resource, inherit = '')
    user_assignment = resource.user_assignments.find_by(user: user)

    return '' if [Project, Protocol].include?(resource.class) && inherit.blank?

    if user_assignment.automatically_assigned? && resource.permission_parent.present?
      parent = resource.permission_parent
      return user_assignment_resource_role_name(user, parent, '_inherit')
    end

    t("access_permissions.partials.#{resource.class.to_s.downcase}_tooltip#{inherit}")
  end
end
