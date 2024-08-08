# frozen_string_literal: true

module Lists
  class StorageLocationSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :id, :code, :name, :container, :description, :owned_by, :created_by,
               :created_on, :urls, :metadata, :file_name, :sub_location_count

    def owned_by
      object.team.name
    end

    def metadata
      {
        display_type: object.metadata['display_type'],
        dimensions: object.metadata['dimensions'] || []
      }
    end

    def file_name
      object.image.filename if object.image.attached?
    end

    def created_by
      object.created_by.full_name
    end

    def created_on
      I18n.l(object.created_at, format: :full)
    end

    def sub_location_count
      if object.respond_to?(:sub_location_count)
        object.sub_location_count
      else
        StorageLocation.where(parent_id: object.id).count
      end
    end

    def urls
      show_url = if @object.container
                   storage_location_path(@object)
                 else
                   storage_locations_path(parent_id: object.id)
                 end
      {
        show: show_url,
        update: storage_location_path(@object)
      }
    end
  end
end