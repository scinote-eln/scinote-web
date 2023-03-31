# frozen_string_literal: true

json.html controller.render_to_string(
  partial: 'access_permissions/partials/new_assignments_form',
  formats: [:html],
  locals: {
    assignable: @project,
    form_object: @user_assignment,
    users: @available_users,
    create_path: access_permissions_projects_path(id: @project.id),
    assignable_path: edit_access_permissions_project_path(@project)
  },
  layout: false
)
