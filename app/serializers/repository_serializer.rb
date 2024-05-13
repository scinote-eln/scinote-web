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
      import_records: import_records_repository_path(object)
    }
  end
end
