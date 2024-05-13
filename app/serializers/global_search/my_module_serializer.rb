# frozen_string_literal: true

module GlobalSearch
  class MyModuleSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :id, :name, :code, :created_at, :updated_at, :team, :experiment, :archived, :url

    def team
      {
        name: object.experiment.project.team.name,
        url: dashboard_path(team: object.team)
      }
    end

    def experiment
      archived = object.experiment.archived_branch?
      {
        name: object.experiment.name,
        url: my_modules_experiment_path(object.experiment.id, view_mode: view_mode(archived)),
        archived: archived
      }
    end

    def created_at
      I18n.l(object.created_at, format: :full_date)
    end

    def updated_at
      I18n.l(object.updated_at, format: :full_date)
    end

    def archived
      object.archived_branch?
    end

    def url
      protocols_my_module_path(object.id, view_mode: view_mode(archived))
    end

    private

    def view_mode(archived)
      archived ? 'archived' : 'active'
    end
  end
end
