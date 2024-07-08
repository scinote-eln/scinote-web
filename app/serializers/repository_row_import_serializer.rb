# frozen_string_literal: true

class RepositoryRowImportSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :code, :import_status, :import_message

  has_many :repository_cells, serializer: RepositoryCellImportSerializer

  attribute :code do
    object.new_record? ? nil : object.code
  end
end
