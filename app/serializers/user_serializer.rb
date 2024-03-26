# frozen_string_literal: true

class UserSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers

  attributes :id, :name, :avatar_url
  attribute :current_user

  def avatar_url
    avatar_path(object, :icon_small)
  end

  def current_user
    instance_options[:user].id == object.id
  end
end
