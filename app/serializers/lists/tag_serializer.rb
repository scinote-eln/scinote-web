# frozen_string_literal: true

module Lists
  class TagSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers
    include Canaid::Helpers::PermissionsHelper

    attributes :id, :name, :color, :created_by, :created_at, :updated_at, :team_id,
               :permissions, :last_modified_by, :taggings_count

    def created_by
      object.created_by.name
    end

    def taggings_count
      object['taggings_count']
    end

    def last_modified_by
      object.last_modified_by&.name
    end

    def created_at
      I18n.l(object.created_at, format: :full_date)
    end

    def updated_at
      I18n.l(object.updated_at, format: :full_date)
    end

    def permissions
      {
        manage: true
      }
    end
  end
end
