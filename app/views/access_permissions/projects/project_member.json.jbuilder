# frozen_string_literal: true

json.form controller.render_to_string(
  partial: 'access_permissions/partials/member_field',
  formats: [:html],
  locals: {
    user: @user_assignment.user,
    assignable: @project,
    update_path: access_permissions_project_path(@project),
    delete_path: access_permissions_project_path(@project, user_id: @user_assignment.user.id)
  },
  layout: false
)
