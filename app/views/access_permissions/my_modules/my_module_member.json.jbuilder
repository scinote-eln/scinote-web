# frozen_string_literal: true

json.form controller.render_to_string(
  partial: 'access_permissions/partials/member_field',
  formats: [:html],
  locals: {
    user: @user_assignment.user,
    with_inherit: true,
    object: @my_module,
    update_path: access_permissions_project_experiment_my_module_path(@project,
                                                                      @experiment,
                                                                      @my_module)
  },
  layout: false
)
