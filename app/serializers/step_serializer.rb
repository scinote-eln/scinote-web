class StepSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :name, :position, :completed, :urls

  def urls
    {
      delete_url: step_path(object),
      state_url: toggle_step_state_step_path(object),
      update_url: step_path(object)
    }
  end
end
