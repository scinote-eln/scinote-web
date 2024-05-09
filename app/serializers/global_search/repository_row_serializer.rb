# frozen_string_literal: true

module GlobalSearch
  class RepositoryRowSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :id, :name, :code, :created_at, :created_by, :team, :repository, :archived, :url

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

    def repository
      archived = object.repository.archived
      {
        name: object.repository.name,
        url: repository_path(object.repository, view_mode: archived ? 'archived' : 'active'),
        archived: archived
      }
    end

    def url
      params = {
        id: object.repository_id,
        landing_page: true,
        row_id: object.id
      }
      params[:archived] = true if object.archived
      repository_path(params)
    end
  end
end
