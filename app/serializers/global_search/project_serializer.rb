# frozen_string_literal: true

class GlobalSearch::ProjectSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :code, :created_at, :team, :folder, :archived, :url

  def team
    {
      name: object.team.name,
      url: projects_path(team: object.team)
    }
  end

  def created_at
    I18n.l(object.created_at, format: :full_date)
  end

  def url
    project_path(object)
  end

  def folder
    if object.project_folder
      {
        name: object.project_folder.name,
        url: project_folder_path(object.project_folder),
        archived: object.project_folder.archived?
      }
    end
  end
end
