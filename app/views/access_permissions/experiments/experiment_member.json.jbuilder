# frozen_string_literal: true

json.form controller.render_to_string(
  partial: 'access_permissions/partials/member_field',
  formats: [:html],
  locals: {
    user: @user_assignment.user,
    assignable: @experiment,
    with_inherit: true,
    update_path: access_permissions_experiment_path(@experiment)
  },
  layout: false
)
