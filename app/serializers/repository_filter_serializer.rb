# frozen_string_literal: true

class RepositoryFilterSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :name, :delete_url, :show_url

  def delete_url
    repository_repository_table_filter_path(object.repository, object)
  end

  def show_url
    repository_repository_table_filter_path(object.repository, object)
  end
end
