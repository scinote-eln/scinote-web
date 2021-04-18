# frozen_string_literal: true

json.modal controller.render_to_string(
  partial: 'access_permissions/modals/edit_modal',
  formats: [:html],
  locals: { resource: @project, update_path: access_permissions_project_path(@project, format: :json), new_resource_path: new_access_permissions_project_path  },
  layout: false
)
