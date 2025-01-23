# frozen_string_literal: true

json.html controller.render_to_string(
  partial: 'access_permissions/modals/edit_modal',
  formats: [:html],
  locals: {
    assignable: @form,
    top_level_assignable: @form,
    manually_assigned_users: @form.manually_assigned_users,
    update_path: access_permissions_form_path(@form),
    new_assignment_path: new_access_permissions_form_path(id: @form)
  },
  layout: false
)

json.flash @message
