# frozen_string_literal: true

json.modal controller.render_to_string(
  partial: 'access_permissions/modals/show_modal',
  formats: [:html],
  locals: {
    assignable: @protocol,
    top_level_assignable: @protocol,
    manually_assigned_users: @protocol.manually_assigned_users
  },
  layout: false
)
