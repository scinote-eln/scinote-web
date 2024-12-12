# frozen_string_literal: true

json.html controller.render_to_string(
  partial: 'access_permissions/partials/new_assignments_form',
  formats: [:html],
  locals: {
    assignable: @form,
    form_object: @user_assignment,
    users: current_team.users.where.not(id: @form.manually_assigned_users.select(:id)),
    create_path: access_permissions_forms_path(id: @form.id),
    assignable_path: edit_access_permissions_form_path(@form)
  },
  layout: false
)
