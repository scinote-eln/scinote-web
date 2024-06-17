# frozen_string_literal: true

class RepositorySerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :urls, :id, :team_id, :repository_columns, :name, :export_actions, :team_name

  def repository_columns
    object.repository_columns.pluck(:id, :name, :data_type)
  end

  def team_name
    object.team.name
  end

  def export_actions
    {
      path: export_repositories_team_path(object.team),
      export_file_type: current_user.settings[:repository_export_file_type] || 'xlsx'
    }
  end

  def urls
    {
      parse_sheet: parse_sheet_repository_path(object),
      import_records: import_records_repository_path(object),
      export_empty_repository: export_empty_repository_team_repository_path(object.team, object)
    }
  end
end
