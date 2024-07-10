# frozen_string_literal: true

module Lists
  class StorageLocationSerializer < ActiveModel::Serializer
    attributes :id, :code, :name, :container, :description, :owned_by, :created_by, :created_on

    def owned_by
      object.team.name
    end

    def created_by
      object.created_by.full_name
    end

    def created_on
      I18n.l(object.created_at, format: :full)
    end
  end
end
