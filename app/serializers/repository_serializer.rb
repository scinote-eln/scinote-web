# frozen_string_literal: true

class RepositorySerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :urls, :id, :team_id, :repository_columns

  def repository_columns
    object.repository_columns.pluck(:id, :name, :data_type)
  end

  def urls
    {
      parse_sheet: parse_sheet_repository_path(object),
      import_records: import_records_repository_path(object),
      export_repository: export_repositories_team_path(object.team, file_type: :csv, repository_ids: object.id),
    }
  end
end
