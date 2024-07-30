# frozen_string_literal: true

module Lists
  class StorageLocationRepositoryRowSerializer < ActiveModel::Serializer
    include Canaid::Helpers::PermissionsHelper

    attributes :created_by, :created_on, :position, :row_id, :row_name, :hidden

    def row_id
      object.repository_row.id unless hidden
    end

    def row_name
      object.repository_row.name unless hidden
    end

    def created_by
      object.created_by.full_name unless hidden
    end

    def created_on
      I18n.l(object.created_at, format: :full)
    end

    def position
      object.metadata['position']
    end

    def hidden
      !can_read_repository?(object.repository_row.repository)
    end
  end
end
