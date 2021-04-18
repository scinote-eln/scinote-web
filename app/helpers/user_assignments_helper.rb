# frozen_string_literal: true

module UserAssignmentsHelper
  def current_assignee_name(assignee)
    display_name = if assignee == current_user
                     [assignee.name, t('user_assignment.current_assignee')].join(' ')
                   else
                     assignee.name
                   end
    sanitize_input(display_name)
  end
end
