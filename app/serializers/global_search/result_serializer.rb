# frozen_string_literal: true

module GlobalSearch
  class ResultSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :id, :name, :created_at, :updated_at, :team, :experiment, :my_module, :archived, :url

    def team
      {
        name: object.my_module.experiment.project.team.name,
        url: projects_path(team_id: object.my_module.experiment.project.team.id)
      }
    end

    def experiment
      {
        name: object.my_module.experiment.name,
        url: my_modules_experiment_path(object.my_module.experiment.id)
      }
    end

    def my_module
      {
        name: object.my_module.name,
        url: protocols_my_module_path(object.my_module.id)
      }
    end

    def created_at
      I18n.l(object.created_at, format: :full_date)
    end

    def updated_at
      I18n.l(object.updated_at, format: :full_date)
    end

    def url
      my_module_results_path(my_module_id: object.my_module.id)
    end
  end
end
