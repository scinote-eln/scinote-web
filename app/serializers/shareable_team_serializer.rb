# frozen_string_literal: true

class ShareableTeamSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include Canaid::Helpers::PermissionsHelper

  attributes :id, :name, :readable, :private_shared_with, :private_shared_with_write

  def name
    readable && object.name
  end

  def readable
    can_read_team?(object)
  end

  def private_shared_with
    model.private_shared_with?(object)
  end

  def private_shared_with_write
    model.private_shared_with_write?(object)
  end

  private

  def model
    scope[:model] || @instance_options[:model]
  end
end
