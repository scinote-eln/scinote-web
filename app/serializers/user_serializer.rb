# frozen_string_literal: true

class UserSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers

  attributes :id, :name, :avatar_url

  def avatar_url
    avatar_path(object, :icon_small)
  end
end
