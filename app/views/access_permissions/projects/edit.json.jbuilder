# frozen_string_literal: true

json.html controller.render_to_string(
  partial: 'access_permissions/projects/modals/edit_modal',
  formats: [:html],
  locals: {
    project: @project,
    update_path: access_permissions_project_path(@project),
    new_resource_path: new_access_permissions_project_path(id: @project)
  },
  layout: false
)

json.flash @message
