# frozen_string_literal: true

class ShareableLinksSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :shareable_url, :description

  def shareable_url
    shared_protocol_url(object.uuid)
  end
end
