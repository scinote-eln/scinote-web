# frozen_string_literal: true

class RepositorySerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :urls, :id, :team_id

  def urls
    {
      parse_sheet: parse_sheet_repository_path(object)
    }
  end
end
