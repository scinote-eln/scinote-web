# frozen_string_literal: true

module GlobalSearch
  class ReportSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :id, :name, :code, :created_at, :updated_at, :created_by, :team, :project, :url

    def team
      {
        name: object.team.name,
        url: projects_path(team: object.team)
      }
    end

    def project
      {
        name: object.project.name,
        url: project_experiments_path(project_id: object.project.id),
        archived: object.project.archived?
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
      reports_path(search: object.code)
    end
  end
end
