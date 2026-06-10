# frozen_string_literal: true

class RepositoryRowSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :code, :url

  has_many :repository_cells, serializer: RepositoryCellImportSerializer

  def url
    repository_repository_row_path(object.repository, object)
  end

end
