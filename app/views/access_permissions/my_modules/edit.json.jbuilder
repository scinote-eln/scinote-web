# frozen_string_literal: true

json.modal controller.render_to_string(
  partial: 'access_permissions/my_modules/modals/edit_modal',
  formats: [:html],
  locals: {
    my_module: @my_module,
    experiment: @experiment,
    project: @project,
    users: @my_module.users
  },
  layout: false
)
