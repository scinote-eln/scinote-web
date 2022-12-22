# frozen_string_literal: true

json.form controller.render_to_string(
  partial: 'access_permissions/partials/protocol_member_field',
  formats: [:html],
  locals: {
    user: @user_assignment.user,
    protocol: @protocol,
    update_path: access_permissions_protocol_path(@protocol)
  },
  layout: false
)
