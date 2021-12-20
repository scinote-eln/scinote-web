# frozen_string_literal: true

json.modal controller.render_to_string(
  partial: 'access_permissions/projects/modals/edit_modal',
  formats: [:html],
  locals: {
    project: @project,
    update_path: access_permissions_project_path(@project),
    new_resource_path: new_access_permissions_project_path(id: @project)
  },
  layout: false
)

modal_container = controller.render_to_string(
  partial: 'access_permissions/partials/edit_assignments_content',
  formats: [:html],
  locals: {
    project: @project,
    update_path: access_permissions_project_path(@project),
    new_resource_path: new_access_permissions_project_path(id: @project)
  },
  layout: false
)

json.html modal_container
json.form modal_container

json.flash @message
