# frozen_string_literal: true

module Lists
  class StorageLocationSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers
    include ShareableSerializer
    include ApplicationHelper
    include ActionView::Helpers::TextHelper

    attributes :id, :code, :name, :container, :description, :owned_by, :created_by,
               :created_on, :urls, :metadata, :file_name, :sub_location_count, :is_empty,
               :img_url, :sa_description

    def owned_by
      object['team_name']
    end

    def img_url
      return unless object.image.attached?

      Rails.application.routes.url_helpers.url_for(object.image)
    end

    def is_empty
      object.empty?
    end

    def sa_description
      @user = scope[:user] || @instance_options[:user]
      custom_auto_link(object.description,
                       simple_format: false,
                       tags: %w(img),
                       team: object.team)
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
      object['created_by_full_name']
    end

    def created_on
      I18n.l(object.created_at, format: :full)
    end

    def sub_location_count
      return '/' if @object.container

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
        update: storage_location_path(@object),
        shareable_teams: shareable_teams_team_shared_objects_path(
          current_user.current_team, object_id: object.id, object_type: object.class.name
        ),
        share: team_shared_objects_path(current_user.current_team, object_id: object.id, object_type: object.class.name)
      }
    end
  end
end
