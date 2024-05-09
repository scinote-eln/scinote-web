# frozen_string_literal: true

module GlobalSearch
  class MyModuleSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :id, :name, :code, :created_at, :updated_at, :team, :experiment, :archived, :url

    def team
      {
        name: object.experiment.project.team.name,
        url: projects_path(team_id: object.experiment.project.team.id)
      }
    end

    def experiment
      {
        name: object.experiment.name,
        url: my_modules_experiment_path(object.experiment.id),
        archived: object.experiment.archived?
      }
    end

    def created_at
      I18n.l(object.created_at, format: :full_date)
    end

    def updated_at
      I18n.l(object.updated_at, format: :full_date)
    end

    def url
      protocols_my_module_path(object.id)
    end
  end
end
