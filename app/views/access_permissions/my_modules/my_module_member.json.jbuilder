# frozen_string_literal: true

json.form controller.render_to_string(
  partial: 'access_permissions/partials/member_field',
  formats: [:html],
  locals: {
    user: @user_assignment.user,
    update_path: access_permissions_my_module_path(@my_module),
    with_inherit: true,
    assignable: @my_module
  },
  layout: false
)
