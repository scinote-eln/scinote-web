# frozen_string_literal: true

json.html controller.render_to_string(
  partial: 'access_permissions/modals/edit_modal',
  formats: [:html],
  locals: {
    assignable: @project,
    manually_assigned_users: @project.manually_assigned_users,
    top_level_assignable: @project,
    new_assignment_path: new_access_permissions_project_path(id: @project)
  },
  layout: false
)

json.flash @message
