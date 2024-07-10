# frozen_string_literal: true

module Lists
  class StorageLocationRepositoryRowSerializer < ActiveModel::Serializer
    attributes :created_by, :created_on, :position

    belongs_to :repository_row, serializer: RepositoryRowSerializer

    def created_by
      object.created_by.full_name
    end

    def created_on
      I18n.l(object.created_at, format: :full)
    end

    def position
      object.metadata['position']
    end
  end
end
