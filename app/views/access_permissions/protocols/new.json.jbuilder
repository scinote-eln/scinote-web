# frozen_string_literal: true

json.html controller.render_to_string(
  partial: 'access_permissions/partials/new_assignments_form',
  formats: [:html],
  locals: {
    resource: @protocol,
    form_object: @form,
    create_path: access_permissions_protocol_path(id: @protocol.id),
    resource_path: edit_access_permissions_protocol_path(@protocol)
  },
  layout: false
)
