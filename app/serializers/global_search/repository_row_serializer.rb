# frozen_string_literal: true

module GlobalSearch
  class RepositoryRowSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :id, :name, :code, :created_at, :created_by, :team, :repository, :archived, :url

    def team
      {
        name: object.team.name,
        url: repository_path(object.repository)
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
      {
        name: object.repository.name,
        url: repository_path(object.repository)
      }
    end

    def url
      # switch to repository_repository_rows_path when inventory items page is implemented
      repository_path(object.repository)
    end
  end
end
