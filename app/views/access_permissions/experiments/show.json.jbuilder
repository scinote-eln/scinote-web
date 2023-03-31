# frozen_string_literal: true

json.modal controller.render_to_string(
  partial: 'access_permissions/modals/show_modal',
  formats: [:html],
  locals: {
    assignable: @experiment,
    top_level_assignable: @project,
    manually_assigned_users: @project.manually_assigned_users
  },
  layout: false
)
