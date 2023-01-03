# frozen_string_literal: true

json.modal controller.render_to_string(
  partial: 'access_permissions/protocols/modals/show_modal',
  formats: [:html],
  locals: {
    protocol: @protocol,
    users: @protocol.assigned_users,
    can_manage_resource: can_manage_protocol_users?(@protocol)
  },
  layout: false
)
