# frozen_string_literal: true

json.modal controller.render_to_string(
  partial: 'access_permissions/projects/modals/show_modal',
  formats: [:html],
  locals: {
    project: @project,
    users: @project.manually_assigned_users,
    can_manage_resource: can_manage_project_users?(@project)
  },
  layout: false
)
