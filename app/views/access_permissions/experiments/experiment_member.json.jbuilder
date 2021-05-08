# frozen_string_literal: true

json.form controller.render_to_string(
  partial: 'access_permissions/partials/experiment_member_field',
  formats: [:html],
  locals: {
    user: @experiment_member.user,
    experiment: @experiment_member.experiment,
    project: @experiment_member.project,
    update_path: access_permissions_project_experiment_path(@experiment_member.project, @experiment_member.experiment)
  },
  layout: false
)
