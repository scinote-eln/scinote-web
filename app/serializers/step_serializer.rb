class StepSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :name, :position, :completed, :urls

  def urls
    {
      delete_url: step_path(object)
    }
  end
end
