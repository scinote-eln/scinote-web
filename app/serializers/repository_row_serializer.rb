# frozen_string_literal: true

class RepositoryRowSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :code

  has_many :repository_cells, serializer: RepositoryCellSerializer
end
