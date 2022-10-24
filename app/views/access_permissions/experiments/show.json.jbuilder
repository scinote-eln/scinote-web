# frozen_string_literal: true

json.modal controller.render_to_string(
  partial: 'access_permissions/experiments/modals/show_modal',
  formats: [:html],
  locals: {
    experiment: @experiment,
    users: @experiment.manually_assigned_users,
    project_path: project_path(@project)
  },
  layout: false
)
