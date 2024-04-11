# frozen_string_literal: true

module GlobalSearch
  class ProjectFolderSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :id, :name, :code, :created_at, :team, :parent_folder, :archived, :url

    def team
      {
        name: object.team.name,
        url: projects_path(project_folder_id: object.id)
      }
    end

    def created_at
      I18n.l(object.created_at, format: :full_date)
    end

    def url
      project_folder_path(object)
    end

    def parent_folder
      if object.parent_folder_id?
        {
          name: object.parent_folder.name,
          url: project_folder_path(object.parent_folder.id),
          archived: object.parent_folder.archived?
        }
      end
    end
  end
end
