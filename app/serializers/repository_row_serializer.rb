# frozen_string_literal: true

class RepositoryRowSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :code

  def urls
    {
    }
  end
end
