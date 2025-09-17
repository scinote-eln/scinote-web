# frozen_string_literal: true

class TagSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :name, :color, :urls

  def urls
    {
      update: team_tag_path(object.team, object, format: :json)
    }
  end
end
