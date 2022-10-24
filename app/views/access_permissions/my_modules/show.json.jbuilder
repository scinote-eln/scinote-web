# frozen_string_literal: true

json.modal controller.render_to_string(
  partial: 'access_permissions/my_modules/modals/show_modal',
  formats: [:html],
  locals: {
    my_module: @my_module,
    experiment: @experiment,
    users: @my_module.manually_assigned_users
  },
  layout: false
)
