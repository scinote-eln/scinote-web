# frozen_string_literal: true

json.form controller.render_to_string(
  partial: 'access_permissions/partials/member_field',
  formats: [:html],
  locals: {
    user: @user_assignment.user,
    assignable: @protocol,
    update_path: access_permissions_protocol_path(@protocol),
    delete_path: access_permissions_protocol_path(@protocol, user_id: @user_assignment.user_id)
  },
  layout: false
)
