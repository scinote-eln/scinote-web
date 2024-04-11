# frozen_string_literal: true

module GlobalSearch
  class ExperimentSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :id, :name, :code, :created_at, :team, :project, :archived, :url

    def team
      {
        name: object.project.team.name,
        url: projects_path(team_id: object.project.team.id)
      }
    end

    def project
      {
        name: object.project.name,
        url: project_experiments_path(project_id: object.project.id),
        archived: object.project.archived?
      }
    end

    def created_at
      I18n.l(object.created_at, format: :full_date)
    end

    def url
      my_modules_experiment_path(object.id)
    end
  end
end
