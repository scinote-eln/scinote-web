# frozen_string_literal: true

class ShareableTeamSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :private_shared_with, :private_shared_with_write

  def private_shared_with
    repository.private_shared_with?(object)
  end

  def private_shared_with_write
    repository.private_shared_with_write?(object)
  end

  private

  def repository
    scope[:repository] || @instance_options[:repository]
  end
end
