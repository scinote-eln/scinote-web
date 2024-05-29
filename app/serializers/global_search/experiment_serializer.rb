# frozen_string_literal: true

module GlobalSearch
  class ExperimentSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :id, :name, :code, :created_at, :team, :project, :archived, :url

    def team
      {
        name: object.project.team.name,
        url: dashboard_path(team: object.team)
      }
    end

    def project
      archived = object.project.archived?
      {
        name: object.project.name,
        url: project_experiments_path(project_id: object.project.id, view_mode: view_mode(archived)),
        archived: archived
      }
    end

    def archived
      object.archived_branch?
    end

    def created_at
      I18n.l(object.created_at, format: :full_date)
    end

    def url
      my_modules_experiment_path(object.id, view_mode: view_mode(archived))
    end

    private

    def view_mode(archived)
      archived ? 'archived' : 'active'
    end
  end
end
