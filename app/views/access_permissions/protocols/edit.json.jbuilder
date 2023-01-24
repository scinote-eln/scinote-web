# frozen_string_literal: true

json.html controller.render_to_string(
  partial: 'access_permissions/protocols/modals/edit_modal',
  formats: [:html],
  locals: {
    protocol: @protocol,
    update_path: access_permissions_protocol_path(@protocol),
    new_resource_path: new_access_permissions_protocol_path(id: @protocol)
  },
  layout: false
)

json.flash @message
