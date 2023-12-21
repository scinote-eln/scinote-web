# frozen_string_literal: true

class TagSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :name, :color, :urls

  def urls
    {
      update: project_tag_path(object.project, object, format: :json)
    }
  end
end
