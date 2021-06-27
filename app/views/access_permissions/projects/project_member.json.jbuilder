# frozen_string_literal: true

json.form controller.render_to_string(
  partial: 'access_permissions/partials/project_member_field',
  formats: [:html],
  locals: {
    user: @form.user,
    project: @project,
    update_path: access_permissions_project_path(@project)
  },
  layout: false
)
