# frozen_string_literal: true

json.form controller.render_to_string(
  partial: 'access_permissions/partials/my_module_member_field',
  formats: [:html],
  locals: {
    user: @my_module_member.user,
    experiment: @my_module_member.experiment,
    my_module: @my_module_member.my_module,
    project: @my_module_member.project,
    update_path: access_permissions_project_experiment_my_module_path(@my_module_member.project,
                                                                      @my_module_member.experiment,
                                                                      @my_module_member.my_module)
  },
  layout: false
)
