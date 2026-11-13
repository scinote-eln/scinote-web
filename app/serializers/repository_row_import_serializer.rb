# frozen_string_literal: true

class RepositoryRowImportSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :code, :import_status, :import_message

  has_many :repository_cells, serializer: RepositoryCellImportSerializer

  attribute :code do
    object.new_record? ? nil : object.code
  end

  attribute :import_cell_errors do
    object.import_cell_errors || {}
  end

  attribute :import_changed_columns do
    object.import_changed_columns || []
  end

  attribute :import_mandatory_missing do
    object.import_mandatory_missing || []
  end
end
