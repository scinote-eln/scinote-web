# frozen_string_literal: true

json.modal controller.render_to_string(
  partial: 'access_permissions/modals/show_modal',
  formats: [:html],
  locals: {
    assignable: @form,
    top_level_assignable: @form,
    manually_assigned_users: @form.manually_assigned_users
  },
  layout: false
)
