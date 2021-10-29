# frozen_string_literal: true

json.modal controller.render_to_string(
  partial: 'access_permissions/experiments/modals/edit_modal',
  formats: [:html],
  locals: {
    experiment: @experiment,
    project: @project,
    users: @experiment.users,
    project_path: project_path(@project)
  },
  layout: false
)
