# frozen_string_literal: true

json.form controller.render_to_string(
  partial: 'access_permissions/partials/default_public_user_role_form',
  formats: [:html],
  locals: {
    assignable: @project,
    editable: true
  },
  layout: false
)
