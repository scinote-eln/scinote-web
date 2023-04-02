# frozen_string_literal: true

json.html controller.render_to_string(
  partial: 'access_permissions/modals/edit_modal',
  formats: [:html],
  locals: {
    assignable: @protocol,
    top_level_assignable: @protocol,
    manually_assigned_users: @protocol.manually_assigned_users,
    update_path: access_permissions_protocol_path(@protocol),
    new_assignment_path: new_access_permissions_protocol_path(id: @protocol)
  },
  layout: false
)

json.flash @message
