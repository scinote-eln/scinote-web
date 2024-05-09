# frozen_string_literal: true

module GlobalSearch
  class ProtocolSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :id, :name, :code, :created_at, :updated_at, :created_by, :team, :archived, :url

    def team
      {
        name: object.team.name,
        url: dashboard_path(team: object.team)
      }
    end

    def created_by
      {
        name: object.created_by.name,
        avatar_url: avatar_path(object.created_by, :icon_small)
      }
    end

    def created_at
      I18n.l(object.created_at, format: :full_date)
    end

    def updated_at
      I18n.l(object.updated_at, format: :full_date)
    end

    def url
      protocol_path(object)
    end
  end
end
