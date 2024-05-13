# frozen_string_literal: true

module GlobalSearch
  class ProjectFolderSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :id, :name, :code, :created_at, :team, :parent_folder, :archived, :url

    def team
      {
        name: object.team.name,
        url: dashboard_path(team: object.team)
      }
    end

    def created_at
      I18n.l(object.created_at, format: :full_date)
    end

    def url
      project_folder_path(object, team: object.team, view_mode: view_mode(object.archived?))
    end

    def parent_folder
      if object.parent_folder_id?
        archived = object.parent_folder.archived?
        {
          name: object.parent_folder.name,
          url: project_folder_path(object.parent_folder.id, team: object.team, view_mode: view_mode(archived)),
          archived: archived
        }
      end
    end

    private

    def view_mode(archived)
      archived ? 'archived' : 'active'
    end
  end
end
