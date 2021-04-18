# frozen_string_literal: true

json.modal controller.render_to_string(
  partial: 'access_permissions/modals/show_modal',
  formats: [:html],
  locals: { resource: @project },
  layout: false
)
